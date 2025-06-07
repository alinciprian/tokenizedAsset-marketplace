//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AssetToken} from "./AssetToken.sol";

contract TokenizationCampaign {
    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error TokenizationCampaign__OnlyOrganizer();

    /*//////////////////////////////////////////////////////////////////////////
                                  VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// Desired price for the item that is tokenized
    uint256 itemPrice;
    /// Number of tokens issued for the asset
    uint256 totalShares = 100;
    /// Computed by dividing the itemPrice with the number of tokens issued;
    uint256 sharePrice;
    /// Sets a maximum amount of shares a user can buy if a certain amount of decentralization is desired;
    uint256 maxSharesPerUser;
    /// Keeps track of how many shares remains to be bought
    uint256 sharesLeft = 100;
    /// Ending time of the campaign;
    uint256 deadline;
    /// Amount of capital already raised;
    uint256 totalRaised;
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

    function buyShares(uint256 _sharesAmount) external {
        /// function used to allow users to buy shares
        /// we need checks regarding how many shares are left, deadline, or if the campaign is fully funded
    }

    function redeemShares() external {}

    function refund() external {}

    function finishCampaign() external onlyOrganizer {}
}
