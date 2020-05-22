pragma solidity ^0.6.0;

import './ABDKMath64x64.sol';

contract Exchange {
    enum TokenType { ERC20, ERC1155, REWARD_COURTS }

    struct Token {
        TokenType tokenType;
        address contractAddress;
        uint256 token;
    }

    function tokenHash(Token token) returns (uint256) {
        if (token.tokenType == ERC20) {
            return keccak256(token.tokenType, token.contractAddress);
        } else {
            return keccak256(token.tokenType, token.contractAddress, token.token);
        }
    }

    // token hash => value (ABDKMath fixed point)
    mapping (uint256 => int128) rates;

    // token hash => LIMIT
    mapping (uint256 => uint256) limits;

    Token[] allTokens;

    function setAllTokenRates(Token[] _tokens, uint256[] _rates) {
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

    function setTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] = _limit;
    }

    function addToTokenLimit(Token token, uint256 _limit) {
        uint256 hash = tokenHash(token);
        limits[hash] += _limit; // FIXME: safe arithmetic
    }

    function setTokenLimits(Token[] _tokens, uint256[] _limits) {
        for (uint j=0; j<_tokens.length; ++j) {
            uint256 hash = tokenHash(_tokens[j]);
            limits[hash] = _limits[j];
        }
    }

    function addToTokenLimits(Token[] _tokens, uint256[] _limits) {
        for (uint j=0; j<_tokens.length; ++j) {
            uint256 hash = tokenHash(_tokens[j]);
            limits[hash] += _limits[j]; // FIXME: safe arithmetics
        }
    }

    function exchange(Token _from, Token _to, uint256 _fromAmount, bytes calldata _data) {
        int128 rate = divi(rates[tokenHash(_to)], divi(rates[tokenHash(_from)]));
        uint256 _toAmount = mulu(rate, _fromAmount);

        require(limit[tokenHash(_to)] >= _toAmount, "Token limit exceeded.");

        if (_from.tokenType == ERC20) {
            IERC20(_from.contractAddress).transferFrom(msg.sender, this, _fromAmount);
        } else {
            ERC1155(_from.contractAddress).safeTransferFrom(msg.sender, this, _from.token, _fromAmount, _data);
        }

        if (_to.tokenType == ERC20) {
            IERC20(_to.contractAddress).transferFrom(this, msg.sender, _toAmount);
        } else if (_to.tokenType == ERC1155) {
            ERC1155(_to.contractAddress).safeTransferFrom(this, msg.sender, _to.token, _toAmount, _data);
        } else /*if (_to.tokenType == REWARD_COURTS)*/ {
            RewardCourts(_to.contractAddress).mint(msg.sender, _to.token, _toAmount, _data, []);
        }

        limit[tokenHash(_to)] -= _toAmount; // TODO: Use safe arithmetic instead of require() above.
    }
}