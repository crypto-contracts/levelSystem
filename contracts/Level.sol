//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IAssetBox {
    function burn(
        uint8 roleIndex,
        uint256 tokenID,
        uint256 amount
    ) external;

    function getRole(uint8 index) external view returns (address);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Level is AccessControlUpgradeable {
    bytes32 public constant GAIN_ROLE = keccak256("GAIN_ROLE");
    bytes32 public constant SPEND_ROLE = keccak256("SPEND_ROLE");

    mapping(IERC721 => mapping(uint256 => uint256)) public shades;
    mapping(IERC721 => mapping(uint256 => uint256)) public level;

    uint256[19] private mstRequired;

    address public copper;
    address public mst;

    event Leveled(
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 level
    );
    event Gained(
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );
    event Spended(
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );

    function initialize(
        address _safe,
        address _copper,
        address _mst
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _safe);

        mstRequired = [
            0,
            0,
            0,
            0,
            0,
            5,
            10,
            20,
            30,
            60,
            120,
            280,
            600,
            1240,
            2520,
            5080,
            10200,
            20400,
            40920
        ];

        copper = _copper;
        mst = _mst;
    }

    function gain_shade(
        IERC721 collection,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(GAIN_ROLE) {
        shades[collection][tokenId] += amount;

        emit Gained(collection, tokenId, amount);
    }

    function spend_shade(
        IERC721 collection,
        uint256 tokenId,
        uint256 amount
    ) public onlyRole(SPEND_ROLE) {
        shades[collection][tokenId] -= amount;

        emit Spended(collection, tokenId, amount);
    }

    function _spend_shade(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        require(
            shades[_collection][_tokenId] >= _amount,
            "insufficient shades"
        );

        shades[_collection][_tokenId] -= _amount;
        emit Spended(_collection, _tokenId, _amount);
    }

    function _spend_copper(
        uint8 _roleIndex,
        IERC721 _role,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        address role = IAssetBox(copper).getRole(_roleIndex);
        require(IERC721(role) == _role, "Wrong Role");

        IAssetBox(copper).burn(_roleIndex, _tokenId, _amount);
    }

    function level_up(
        uint8 roleIndex,
        IERC721 collection,
        uint256 tokenId
    ) external {
        require(
            _isApprovedOrOwner(msg.sender, collection, tokenId),
            "Not approved"
        );

        uint256 _level = level[collection][tokenId];
        uint256 _shade_required = shade_required(_level);
        uint256 _copper_required = copper_required(_level);
        uint256 _mst_required = mst_required(_level);

        _spend_shade(collection, tokenId, _shade_required);

        if (_copper_required > 0) {
            _spend_copper(roleIndex, collection, tokenId, _copper_required);
        }

        if (_mst_required > 0) {
            IERC20(mst).transferFrom(
                msg.sender,
                address(this),
                _mst_required * 1e18
            );
        }

        level[collection][tokenId] = _level + 1;

        emit Leveled(collection, tokenId, _level + 1);
    }

    function shade_required(uint256 current_level)
        public
        pure
        returns (uint256 shade_to_next_level)
    {
        shade_to_next_level = current_level * 1000;
        for (uint256 i = 1; i < current_level; i++) {
            shade_to_next_level += i * 1000;
        }
    }

    function mst_required(uint256 _current_level)
        public
        view
        returns (uint256 mst_to_next_level)
    {
        uint256 current_level = _current_level > 18 ? 18 : _current_level;
        mst_to_next_level = mstRequired[current_level];
    }

    function copper_required(uint256 _current_level)
        public
        pure
        returns (uint256 mst_to_next_level)
    {
        mst_to_next_level = _current_level > 0 ? 1024 : 0;

        uint256 current_level = _current_level > 9 ? 9 : _current_level;

        for (uint256 i = 1; i < current_level; i++) {
            mst_to_next_level = mst_to_next_level * 2;
        }

        for (uint256 i = 9; i < _current_level; i++) {
            mst_to_next_level += (mst_to_next_level * 10) / 100;
        }
    }

    function _isApprovedOrOwner(
        address spender,
        IERC721 collection,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = IERC721(collection).ownerOf(tokenId);
        return (spender == owner ||
            IERC721(collection).getApproved(tokenId) == spender ||
            IERC721(collection).isApprovedForAll(owner, spender));
    }
}
