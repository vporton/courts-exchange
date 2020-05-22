pragma solidity ^6.0.0;

contract Exchange :  {
    enum TokenType : uint8 { ERC20, ERC1155 }

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

    void setAllTokenRates(Token[] _tokens, uint256[] _rates) {
        for (uint i=0; i<allTokens.length; ++i) {
            uint256 hash = tokenHash(_tokens[i]);
            limits[hash] = 0; // "nullify" old tokens
        }
        allTokens = _tokens;
        for (uint j=0; j<_tokens.length; ++j) {
            uint256 hash = tokenHash(_tokens[j]);
            rates[hash] = _rates[j];
        }
    }

    void setTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] = _limit;
    }

    void addToTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] += _limit; // FIXME: safe arithmetic
    }

    void setTokenLimits(Token[] _tokens, uint256[] _limits) {
        for (uint j=0; j<_tokens.length; ++j) {
            uint256 hash = tokenHash(_tokens[j]);
            limits[hash] = _limits[j];
        }
    }

    void addToTokenLimits(Token[] _tokens, uint256[] _limits) {
        for (uint j=0; j<_tokens.length; ++j) {
            uint256 hash = tokenHash(_tokens[j]);
            limits[hash] += _limits[j]; // FIXME: safe arithmetics
        }
    }

    void exchange(Token _from, Token _to, uint256 _fromAmount, bytes calldata _data = []) {
        uint256 _toAmount = 0; // FIXME: Use safe arithmetic instead.

        require(limit[tokenHash(_to)] >= _toAmount, "Token limit exceeded.");

        switch (_from.tokenType)
            case ERC20:
                IERC20(_from.contractAddress).transferFrom(msg.sender, this, _fromAmount);
                break;
            case ERC1155:
                ERC1155(_from.contractAddress).safeTransferFrom(msg.sender, this, _from.token, _fromAmount, _data);
        }

        switch (_to.tokenType)
            case ERC20:
                IERC20(_to.contractAddress).transferFrom(this, msg.sender, _toAmount);
                break;
            case ERC1155:
                ERC1155(_to.contractAddress).safeTransferFrom(this, msg.sender, _to.token, _toAmount, _data);
        }

        limit[tokenHash(_to)] -= _toAmount; // TODO: Use safe arithmetic instead of require() above.
    }
}