// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title IBrandVerificationNFT
 * @dev Interface to check brand verification status
 */
interface IBrandVerificationNFT {
    function isVerified(address) external view returns (bool);
}

/**
 * @title ProductSeriesNFT
 * @dev ERC721 contract for minting NFTs associated with product series, with per-token metadata URIs.
 */
contract ProductSeriesNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    uint256 private _tokenIdCounter;

    struct Series {
        uint256 maxSupply;
        uint256 minted;
        address brandOwner;
    }

    /// Mapping seriesId to Series
    mapping(uint256 => Series) public seriesList;

    /// Mapping tokenId to seriesId
    mapping(uint256 => uint256) public tokenIdToSeriesId;

    /// Mapping tokenId to metadata URI
    mapping(uint256 => string) private _tokenURIs;

    /// Series holders (address list)
    mapping(uint256 => address[]) public seriesHolders;

    /// Brand to seriesIds
    mapping(address => uint256[]) public brandSeries;

    IBrandVerificationNFT public verificationContract;

    event SeriesCreated(uint256 indexed seriesId, address indexed brandOwner, uint256 maxSupply);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed seriesId, address indexed to, string metadataURI);

    constructor(address verificationAddress)
        ERC721("Snap Product Series", "SPS")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        verificationContract = IBrandVerificationNFT(verificationAddress);
    }

    function isMinter() public view returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    function isCreator() public view returns (bool) {
        return hasRole(CREATOR_ROLE, msg.sender);
    }

    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function grantCreatorRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CREATOR_ROLE, account);
    }

    /**
     * @notice Create a new series (without baseURI)
     */
    function createSeries(
        uint256 seriesId,
        uint256 maxSupply,
        address brandOwner
    ) external onlyRole(CREATOR_ROLE) {
        require(seriesList[seriesId].maxSupply == 0, "Series already exists");
        require(maxSupply > 0, "Max supply must be positive");
        require(
            verificationContract.isVerified(brandOwner),
            "Brand not verified"
        );

        seriesList[seriesId] = Series({
            maxSupply: maxSupply,
            minted: 0,
            brandOwner: brandOwner
        });

        brandSeries[brandOwner].push(seriesId);

        emit SeriesCreated(seriesId, brandOwner, maxSupply);
    }

    /**
     * @notice Mint a new NFT in a series with per-token metadata URI
     */
    function mintSeries(address to, uint256 seriesId, string calldata metadataURI)
        external
        onlyRole(MINTER_ROLE)
    {
        Series storage s = seriesList[seriesId];
        require(s.maxSupply > 0, "Series does not exist");
        require(s.minted < s.maxSupply, "Series fully minted");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _safeMint(to, tokenId);
        tokenIdToSeriesId[tokenId] = seriesId;
        _tokenURIs[tokenId] = metadataURI;
        s.minted += 1;

        seriesHolders[seriesId].push(to);

        emit NFTMinted(tokenId, seriesId, to, metadataURI);
    }

    /**
     * @notice Return metadata URI of a token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ownerOf(tokenId); // revert if token does not exist
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
