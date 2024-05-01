// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DN404.sol";
import "./DN404Mirror.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract Mintpad is DN404, Ownable {

    string private _name;
    string private _symbol;
    string private _baseURI;
    string private _dataURI;

    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    error RecipientsAmountsMismatch();

    constructor() {
        _initializeOwner(msg.sender);
        _name = "Mintpad Token";
        _symbol = "MINT";

        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(TOTAL_SUPPLY, msg.sender, mirror);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _unit() internal view virtual override returns (uint256) {
        return 10 ** 23;
    }

    function _tokenURI(uint256 tokenId) internal view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
        } else {
            string memory jsonData = string(
                abi.encodePacked(
                    '{"name": "MINT VIP PASS #',
                    LibString.toString(tokenId),
                    '","description":"A collection of 10,000 MINT Token replicants where NFTs and CRC20 tokens converge, offering limitless and exclusive benefits to holders.","external_url":"https://mintpad.network","image":"',
                    _dataURI,
                    '","attributes":"[]"}'
                )
            );

            return string(abi.encodePacked("data:application/json;utf8,", jsonData));
        }
    }
    
    function tokensOf(address owner) public view returns (uint256[] memory result) {
        result = _tokensOfWithChecks(owner);
    }
    
    function _tokensOfWithChecks(address owner) internal view returns (uint256[] memory result) {
        DN404Storage storage $ = _getDN404Storage();
        uint256 n = $.addressData[owner].ownedLength;
        result = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            uint256 id = _get($.owned[owner], i);
            result[i] = id;
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setDataURI(string memory dataURI) public onlyOwner {
        _dataURI = dataURI;
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        if (recipients.length != amounts.length) revert RecipientsAmountsMismatch();

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(address(this), recipients[i], amounts[i] * _unit());
        }
    }

    function withdrawCro() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }
}
