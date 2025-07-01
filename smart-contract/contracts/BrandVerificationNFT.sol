// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title BrandVerificationNFT
 * @dev ERC721 contract to mint a single verification NFT per brand
 *      Payment using native RON (msg.value)
 */
contract BrandVerificationNFT is ERC721, Ownable {
    /// Mapping to track if a wallet is already verified
    mapping(address => bool) public isVerified;

    /// Global counter for unique token IDs
    uint256 private _tokenIdCounter;

    /// Fee required to register brand (0.0001 RON)
    uint256 public constant verificationFee = 1e14; // 0.0001 RON

    /// Base URI for metadata
    string private _baseTokenURI;

    /// Event emitted when a brand is verified
    event BrandVerified(address indexed brand, uint256 tokenId, uint256 amount);

    /**
     * @dev Constructor sets token name, symbol, and initial owner
     */
    constructor()
        ERC721("CertiThread Brand Verification", "CTV")
        Ownable(msg.sender)
    {}

    /**
     * @dev Public function to verify brand
     * Reverts if already verified or fee not met
     * Mints NFT to sender wallet
     */
    function verifyBrand() external payable {
        require(!isVerified[msg.sender], "Brand already verified.");
        require(msg.value >= verificationFee, "Verification fee insufficient.");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _safeMint(msg.sender, tokenId);
        isVerified[msg.sender] = true;

        emit BrandVerified(msg.sender, tokenId, msg.value);
    }

    /**
     * @dev Allow owner to withdraw collected RON fees
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Owner can set base URI for metadata
     * Example: "ipfs://bafybeifc4kbl6dfsvxxtovrdzasyt7cdmzxjto32w3dvfvzi6yr4evhzp4/"
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * @dev Return the metadata URI of a token
     * This does NOT call _exists() to avoid import issues
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json")
        );
    }

    /**
     * @dev Allow contract to receive RON
     */
    receive() external payable {}

    /**
     * @dev Fallback function in case someone sends data
     */
    fallback() external payable {}
}
