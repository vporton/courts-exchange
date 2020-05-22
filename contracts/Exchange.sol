pragma solidity ^6.0.0;

contract Exchange {
    enum TokenType : uint8 { ERC20, ERC721, ERC1155 }

    struct Token {
        TokenType tokenType;
        address contractAddress;
        uint256 token;
    }

    uint256 tokenHash(Token token) returns (uint256) {
        if (token.tokenType == ERC20) {
            return keccak256(token.tokenType, token.contractAddress);
        } else {
            return keccak256(token.tokenType, token.contractAddress, token.token);
        }
    }

    // token hash => value
    mapping (uint256 => uint256) rates;

    // token hash => LIMIT
    mapping (uint256 => uint256) limits;

    Token[] allTokens;

    // FIXME: The argument of setTokenRates() ordered accordingly allTokens (unsafe as allTokens may change), but setTokenLimit uses Token. Inconsistency

    void setTokenRates(uint256[] _rates) {
        // TODO
    }

    void setTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] = _limit;
    }

    void addToTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] += _limit; // FIXME: safe arithmetic
    }
}