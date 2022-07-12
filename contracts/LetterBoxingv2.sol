//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RMRK/RMRKMultiResource.sol";
import "./RMRK/access/RMRKIssuable.sol";

contract LetterBoxingv2 is RMRKIssuable, RMRKMultiResource {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdAuto;
    Counters.Counter private _resourceIdAuto;

    uint256 private _mintFee;
    bool private paused;

    //this is a list of letterbox IDs that exist.
    uint256[] letterboxlist;

    struct OwnedLetterboxesInfo {
        uint256[] letterboxIds;
    }
    //mapping connecting an address to LetterBoxing
    mapping(address => OwnedLetterboxesInfo) internal letterboxesToAddresses;

    // this is to a uint256 and not array or constructor becase stamp to address should be 1:1 relationship
    mapping(address => uint256) internal stampsToAddresses;

    function mapLetterboxAddr(address to_, uint256 tokenId_) private {
        letterboxesToAddresses[to_].letterboxIds.push(tokenId_);
    }

    function mapStampAddr(address to_, uint tokenId_) private {
        //modifier on caller function should be isStampEligible
        // require(
        //     stampsToAddresses[to_] == 0,
        //     "address already has stamp, do not mint"
        // );

        stampsToAddresses[to_] = tokenId_;
    }

    function stampHeldBy(address owner) public view returns (uint256) {
        return stampsToAddresses[owner];
    }

    function letterboxesHeldBy(address owner)
        public
        view
        returns (uint256[] memory)
    {
        // require(
        //     letterboxesToAddresses[owner].letterboxIds[0] > 0,
        //     "user has not minted letterbox"
        // );

        return letterboxesToAddresses[owner].letterboxIds;
    }

    function letterboxList() public view returns (uint256[] memory) {
        return letterboxlist;
    }

    modifier isStampEligible(address to_) {
        //need to cehck to see if address already owns one.
        require(stampHeldBy(to_) == 0, "Only one stamp per address");
        _;
    }

    modifier isNotPaused() {
        require(paused == false, "no minting is permitted at this time");
        _;
    }

    constructor() RMRKMultiResource("NTLetterBoxingV2", "LTRBXv2") {
        _mintFee = 0;
        _resourceIdAuto.increment(); //resource cannot be at index 0 per standard
        _tokenIdAuto.increment(); // it is inconvenient if initial tokenId is 0 so we skip that one.
        paused = false;
    }

    function hasStamp(address owner) public view returns (bool) {
        if (stampHeldBy(owner) == 0) {
            return false;
        } else {
            return true;
        }
    }

    function stampMetadataURI(address owner)
        public
        view
        returns (string memory)
    {
        if (hasStamp(owner) == true) {
            Resource[] memory stamp = getFullResources(stampHeldBy(owner));
            return stamp[0].metadataURI;
        } else {
            return "User does not have stamp";
        }
    }

    function letterboxMetadataURI(uint256 letterboxTokenId)
        public
        view
        returns (string memory)
    {
        //add try catch
        Resource[] memory letterbox = getFullResources(letterboxTokenId);
        return letterbox[0].metadataURI;
    }

    function resourceCount(uint256 tokenId_) public view returns (uint256) {
        return getFullResources(tokenId_).length;
    }

    function createAndAddResource(
        uint256 tokenId_,
        string memory resourceMetadata,
        bool isAccepted
    ) internal {
        uint64 resourceId = nextResourceId();
        uint128[] memory custom;
        addResourceEntry(resourceMetadata, custom);
        addResourceToToken(tokenId_, resourceId, 0); // i believe if overwrite is 0 it will prevent from overwriting a token.

        if (isAccepted == true) {
            uint64[] memory pendingResources = getPendingResources(tokenId_);
            if (pendingResources.length >= 1) {
                uint256 tokenToApprove = pendingResources.length - 1;
                acceptResource(tokenId_, tokenToApprove);
            } else {
                //error
            }
        }
    }

    function stampToLetterbox(
        address stampUser,
        uint256 letterboxTokenId,
        bool accepted
    ) public isNotPaused {
        string memory stampMetadata = stampMetadataURI(stampUser);
        createAndAddResource(letterboxTokenId, stampMetadata, accepted);
    }

    function letterboxToStamp(address stampUser, uint256 letterboxTokenId)
        public
        isNotPaused
    {
        //should add custom data for letterboxer to choose autoaccept
        string memory letterboxMetadata = letterboxMetadataURI(
            letterboxTokenId
        );
        uint256 stampReceiving = stampHeldBy(stampUser);
        createAndAddResource(stampReceiving, letterboxMetadata, true);
    }

    function withdraw() public payable onlyIssuer {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) public isNotPaused {
        //@dev since call requires token exists, assumes a valid token id - act accordingly in interaction.

        _addResourceToToken(tokenId, resourceId, overwrites);
    }

    function acceptResource(uint256 tokenId, uint256 index)
        public
        override
    //    onlyApprovedOrOwner(tokenId)
    {
        super._acceptResource(tokenId, index);
    }

    function addResourceEntry(
        //  uint64 id,  change this to be _resourceIdAuto instead
        string memory metadataURI,
        uint128[] memory custom
    ) public isNotPaused {
        //this is to set the variable as a uint64  - could be an issue if overflow?
        uint64 currentResource = nextResourceId();
        _addResourceEntry(currentResource, metadataURI, custom);
        _resourceIdAuto.increment();
    }

    // function getFullResourcesLb(uint256 tokenId)
    //     public
    //     view
    //     override
    //     returns (Resource[] memory)
    // {
    //     return getFullResources(tokenId);
    // }

    function nextResourceId() public view returns (uint64) {
        uint64 nextResource = uintFixerFun(_resourceIdAuto.current());
        return nextResource;
    }

    //external functions
    function feeSetter(uint256 newMintFee_) public onlyIssuer {
        _mintFee = newMintFee_;
    }

    function feeGetter() public view returns (uint256) {
        return _mintFee;
    }

    function pauseContract(bool state) public onlyIssuer {
        paused = state;
    }

    function isPaused() public view onlyIssuer returns (bool) {
        return paused;
    }

    //hack to solve a problem, probably not a great way to handle this
    function uintFixerFun(uint256 resourceId_) private pure returns (uint64) {
        return uint64(resourceId_);
    }

    //creates a stamp with the URI passed for first (therefore primary) resource
    //automatically adds and approves the initial upload as a resource.

    function mintInitial(address to_, string memory resourceURI_)
        private
        returns (uint256)
    {
        //mint a token to accept the resource.
        uint256 tokenIdNow = _tokenIdAuto.current();
        _safeMint(to_, tokenIdNow);

        //this is an argument we need to pass with the add resource function but currently have not used

        createAndAddResource(tokenIdNow, resourceURI_, true);

        _tokenIdAuto.increment();

        //returns the tokenid used for making this token to be added to a mapping
        return tokenIdNow;
    }

    //this function is for the initial mint of the stamp for
    //those in the "finder" role.
    function mintStamp(address to_, string memory uri_)
        public
        payable
        isStampEligible(to_)
        isNotPaused
    {
        require(
            msg.value >= _mintFee,
            "Insufficient funds sent with transaction"
        );
        uint256 newTokenId;
        newTokenId = mintInitial(to_, uri_);
        mapStampAddr(to_, newTokenId);
    }

    //this function mints new letterboxes, much like new finder stamps
    //however, with no test for a charge
    function mintLetterbox(address to_, string memory uri_) public isNotPaused {
        uint256 newTokenId = mintInitial(to_, uri_);
        mapLetterboxAddr(to_, newTokenId);
        letterboxlist.push(newTokenId);
    }
}
