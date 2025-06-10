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
    error TokenizationCampaign__CampaignStillActive();
    error TokenizationCampaign__NothingToRefund();
    error TokenizationCampaign__CampaignNotSuccesful();

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
    event FundsRedeemed(address organizer, uint256 amountRedeemed);

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

    /// @param _itemName Name of the item being tokenized
    /// @param _symbol Symbol of the item being tokenized
    /// @param _itemPrice The target price
    /// @param _duration Duration of the campaign
    /// @param _maxSharesPerUser The maximum amount of shares one user can buy
    /// @param _paymentToken Address of the token used for payment for this campaign
    /// @param _organizer The address of the organizer. This is the address than can redeem the funds
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

        /// emit event
        emit SharesBought(msg.sender, _sharesAmount, amountToContribute);
    }

    /// Function allows user to redeem the tokens representing shares of the asset
    /// @dev function is meant to be called only if the campaign was succesfull
    function redeemShares() external {
        /// Checks - check if the campaign was succesful
        if (!funded) revert TokenizationCampaign__NotFullyFundedYet();

        /// Efects

        uint256 sharesToRedeem = sharesAquired[msg.sender];
        sharesAquired[msg.sender] = 0;

        /// Interactions - transfer the tokens representing shares to the buyer
        bool success = assetToken.transfer(msg.sender, sharesToRedeem);
        if (!success) revert TokenizationCampaign__TransferFailed();

        /// emit event
        emit SharesRedeemed(msg.sender, sharesToRedeem);
    }

    /// Allows users to get refunded
    /// @dev function is meant to pe called only if the deadline passed and the campaign is not fully funded.
    function refund() external {
        /// Checks
        /// check if the campaign is not succesful or if the deadline passed
        if (!funded || block.timestamp < deadline) revert TokenizationCampaign__CampaignStillActive();
        uint256 refundAmount = amountContributed[msg.sender];
        if (refundAmount == 0) revert TokenizationCampaign__NothingToRefund();

        /// Effects
        amountContributed[msg.sender] = 0;

        /// Interactions

        bool success = IERC20(paymentToken).transfer(msg.sender, refundAmount);
        if (!success) revert TokenizationCampaign__TransferFailed();

        emit UserRefunded(msg.sender, refundAmount);
    }

    /// Once the campaign is succesfull, the organizer cand redeem the funds
    /// @dev function is only meant to be called once the campaign is succesful
    function redeemFunds() external onlyOrganizer {
        if (!funded) revert TokenizationCampaign__CampaignNotSuccesful();
        uint256 redeemAmount = IERC20(paymentToken).balanceOf(address(this));
        bool success = IERC20(paymentToken).transfer(msg.sender, redeemAmount);
        if (!success) revert TokenizationCampaign__TransferFailed();

        emit FundsRedeemed(msg.sender, redeemAmount);
    }
}
