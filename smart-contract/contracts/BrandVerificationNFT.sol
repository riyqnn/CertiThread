// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title BrandVerificationNFT
 * @dev ERC721 contract to mint a single verification NFT per brand
 *      Payment using native MONAD (msg.value)
 */
contract BrandVerificationNFT is ERC721, Ownable {
    /// Mapping to track if a wallet is already verified
    mapping(address => bool) public isVerified;

    /// Mapping tokenId to metadata URI (IPFS)
    mapping(uint256 => string) private _customURIs;

    /// Global counter for unique token IDs
    uint256 private _tokenIdCounter;

    /// Fee required to register brand (0.0001)
    uint256 public constant verificationFee = 1e14; // 0.0001

    /// Event emitted when a brand is verified
    event BrandVerified(address indexed brand, uint256 tokenId, string metadataURI, uint256 amount);

    /**
     * @dev Constructor sets token name and symbol
     */
    constructor()
        ERC721("CertiThread Brand Verification", "CTV")
        Ownable(msg.sender)
    {}

    /**
     * @dev Public function to verify brand
     * Reverts if already verified or fee not met
     * Mints NFT to sender wallet and assigns custom metadata URI
     * @param metadataURI The full IPFS URI (e.g., ipfs://...)
     */
    function verifyBrand(string calldata metadataURI) external payable {
        require(!isVerified[msg.sender], "Brand already verified.");
        require(msg.value == verificationFee, "Verification fee must be exactly 0.0001 MONAD.");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _safeMint(msg.sender, tokenId);
        _customURIs[tokenId] = metadataURI;
        isVerified[msg.sender] = true;

        emit BrandVerified(msg.sender, tokenId, metadataURI, msg.value);
    }

    /**
     * @dev Return the metadata URI of a token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // Reverts if token doesn't exist
        return _customURIs[tokenId];
    }

    /**
     * @dev Owner can update the metadata URI of an existing token
     */
    function setTokenURI(uint256 tokenId, string calldata newURI) external onlyOwner {
        ownerOf(tokenId); // Reverts if token doesn't exist
        _customURIs[tokenId] = newURI;
    }

    /**
     * @dev Allow owner to withdraw collected MONAD fees
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner()).transfer(balance);
    }

    /**
     * @notice Returns the balance of this contract (in wei)
     */
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allow contract to receive MONAD
     */
    receive() external payable {}

    /**
     * @dev Fallback function in case someone sends data
     */
    fallback() external payable {}
}
