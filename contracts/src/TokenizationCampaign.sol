//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AssetToken} from "./AssetToken.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenizationCampaign {
    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error TokenizationCampaign__OnlyOrganizer();
    error TokenizationCampaign__CampaignFullyFunded();
    error TokenizationCampaign__CampaignHasEnded();
    error TokenizationCampaign__InvalidSharesAmount();
    error TokenizationCampaign__TransferFailed();
    error TokenizationCampaign__NotFullyFundedYet();

    /*//////////////////////////////////////////////////////////////////////////
                                  VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// Desired price for the item that is tokenized
    uint256 public itemPrice;
    /// Number of tokens issued for the asset
    uint256 totalShares = 100;
    /// Computed by dividing the itemPrice with the number of tokens issued;
    uint256 public sharePrice;
    /// Sets a maximum amount of shares a user can buy if a certain amount of decentralization is desired;
    uint256 public maxSharesPerUser;
    /// Keeps track of how many shares remains to be bought
    uint256 sharesLeft = 100;
    /// Ending time of the campaign;
    uint256 public deadline;
    /// Amount of capital already raised;
    uint256 public totalRaised;
    /// Address of the organizer - can administrate the campaign
    address organizer;
    /// Address of the supported token of payment -> USDC ?
    address paymentToken;
    /// The assetToken contract
    AssetToken assetToken;

    /// Swith to true once the campaign is fully funded
    bool public funded = false;

    // Keeps track of how many shares each address has bought;
    mapping(address => uint256) public sharesAquired;
    // Keeps track of how much each user contributed;
    mapping(address => uint256) public amountContributed;

    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event SharesBought(address indexed user, uint256 sharesAmount, uint256 contributedAmount);
    event SharesRedeemed(address indexed user, uint256 sharesAmount);
    event UserRefunded(address indexed user, uint256 amountRedunded);

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyOrganizer() {
        if (msg.sender != organizer) revert TokenizationCampaign__OnlyOrganizer();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        string memory _itemName,
        string memory _symbol,
        uint256 _itemPrice,
        uint256 _duration,
        uint256 _maxSharesPerUser,
        address _paymentToken,
        address _organizer
    ) {
        assetToken = new AssetToken(_itemName, _symbol);
        itemPrice = _itemPrice;
        deadline = block.timestamp + _duration * 1 hours;
        maxSharesPerUser = _maxSharesPerUser;
        organizer = _organizer;
        paymentToken = _paymentToken;
        sharePrice = itemPrice / totalShares;
    }

    /// Function used to buy shares of the asset
    /// @param _sharesAmount The amount of shares to be bought
    function buyShares(uint256 _sharesAmount) external {
        /// Checks - that the campaign has not ended, is not fully funded, and the _sharesAmount to be bought is valid;
        if (block.timestamp >= deadline) revert TokenizationCampaign__CampaignHasEnded();
        if (funded) revert TokenizationCampaign__CampaignFullyFunded();
        if (
            _sharesAmount <= 0 || _sharesAmount > sharesLeft
                || sharesAquired[msg.sender] + _sharesAmount > maxSharesPerUser
        ) revert TokenizationCampaign__InvalidSharesAmount();

        /// Effects - Update the database

        sharesAquired[msg.sender] += _sharesAmount;
        /// compute the amount to be paid in exchange for the shares
        uint256 amountToContribute = _sharesAmount * sharePrice;
        amountContributed[msg.sender] += amountToContribute;
        sharesLeft -= _sharesAmount;
        totalRaised += amountToContribute;
        /// if all shares have been bought switch funded to true
        if (sharesLeft == 0) funded = true;

        /// Interaction
        /// transfer funds from the buyer to the contract
        bool success = IERC20(paymentToken).transferFrom(msg.sender, address(this), amountToContribute);
        if (!success) revert TokenizationCampaign__TransferFailed();
        emit SharesBought(msg.sender, _sharesAmount, amountToContribute);
    }

    function redeemShares() external {
        /// Checks - check if the campaign was succesful
        if (!funded) revert TokenizationCampaign__NotFullyFundedYet();

        /// Efects

        uint256 sharesToRedeem = sharesAquired[msg.sender];
        sharesAquired[msg.sender] = 0;

        /// Interactions - transfer the tokens representing shares to the buyer
        bool success = assetToken.transfer(msg.sender, sharesToRedeem);
        if (!success) revert TokenizationCampaign__TransferFailed();
    }

    function refund() external {}

    function finishCampaign() external onlyOrganizer {}
}
