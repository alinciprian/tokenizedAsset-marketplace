//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TokenizationCampaign} from "./TokenizationCampaign.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title CampaignFactory - Factory contract for deploying TokenizationCampaign instances
/// @author AlinCiprian
/// @notice This contract allows the contract owner to deploy new tokenized item investment campaigns
/// @dev Deployed campaigns are tracked by the factory and associated with their organizer's address

contract CampaignFactory is Ownable {
    uint256 campaignNonce;
    address[] public campaigns;
    mapping(address => address[]) campaignByOrganizer;

    constructor() Ownable(msg.sender) {}

    function startNewCampaign(
        string memory _itemName,
        string memory _symbol,
        uint256 _itemPrice,
        uint256 _duration,
        uint256 _maxSharesPerUser,
        address _paymentToken,
        address _organizer
    ) external onlyOwner {
        TokenizationCampaign newCampaign = new TokenizationCampaign(
            _itemName, _symbol, _itemPrice, _duration, _maxSharesPerUser, _paymentToken, _organizer
        );
        campaignNonce++;
        campaigns.push(address(newCampaign));
        campaignByOrganizer[_organizer].push(address(newCampaign));
    }
}
