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

    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

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

    function buyShares() external {}

    function redeemShares() external {}

    function refund() external {}

    function finishCampaign() external onlyOrganizer {}
}
