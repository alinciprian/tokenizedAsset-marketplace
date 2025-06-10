//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TokenizationCampaign} from "./TokenizationCampaign.sol";

contract CampaignFactory {
    TokenizationCampaign newCampaign;
    uint256 campaignNonce;
    mapping(address => uint256) campaignToNonce;
    mapping(address => address) campaignToOrganizer;

    constructor(
        string memory _itemName,
        string memory _symbol,
        uint256 _itemPrice,
        uint256 _duration,
        uint256 _maxSharesPerUser,
        address _paymentToken,
        address _organizer
    ) {
        newCampaign = new TokenizationCampaign(
            _itemName, _symbol, _itemPrice, _duration, _maxSharesPerUser, _paymentToken, _organizer
        );
    }
}
