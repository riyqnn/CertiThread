// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title IBrandVerificationNFT
 * @dev Interface to check brand verification status
 */
interface IBrandVerificationNFT {
    function isVerified(address) external view returns (bool);
}

/**
 * @title ProductSeriesNFT
 * @dev ERC721 contract to mint NFTs per product series
 */
contract ProductSeriesNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _tokenIdCounter;

    struct Series {
        uint256 maxSupply;
        uint256 minted;
        string baseURI;
        address brandOwner;
    }

    mapping(uint256 => Series) public seriesList;
    mapping(uint256 => uint256) public tokenIdToSeriesId;

    IBrandVerificationNFT public verificationContract;

    constructor(address verificationAddress)
        ERC721("CertiThread Product Series", "CTS")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        verificationContract = IBrandVerificationNFT(verificationAddress);
    }

    /**
    * @dev Check if msg.sender has MINTER_ROLE
    */
    function isMinter() public view returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    /**
    * @dev Grant MINTER_ROLE to a specific address
    * Can only be called by DEFAULT_ADMIN_ROLE
    */
    function grantMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }


    function createSeries(
        uint256 seriesId,
        uint256 maxSupply,
        string memory baseURI,
        address brandOwner
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(seriesList[seriesId].maxSupply == 0, "Series already exists");
        require(maxSupply > 0, "Max supply must be positive");
        require(
            verificationContract.isVerified(brandOwner),
            "Brand not verified"
        );

        seriesList[seriesId] = Series(
            maxSupply,
            0,
            baseURI,
            brandOwner
        );
    }

    function mintSeries(address to, uint256 seriesId)
        public
        onlyRole(MINTER_ROLE)
    {
        Series storage s = seriesList[seriesId];
        require(s.maxSupply > 0, "Series does not exist");
        require(s.minted < s.maxSupply, "Series fully minted");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _safeMint(to, tokenId);
        tokenIdToSeriesId[tokenId] = seriesId;
        s.minted += 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // This will revert automatically if token doesn't exist
        ownerOf(tokenId);

        uint256 seriesId = tokenIdToSeriesId[tokenId];
        string memory baseURI = seriesList[seriesId].baseURI;

        return string(
            abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json")
        );
    }

    /**
     * @dev This override is REQUIRED when inheriting ERC721 and AccessControl.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
