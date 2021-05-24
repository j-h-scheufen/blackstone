// SPDX-License-Identifier: Parity-6.0.0
pragma solidity >=0.5;

library Strings {

    uint constant ASCII_ZERO = 48;
    uint constant CEIL_LOG_10_2_256 = 78;

    function concat(string memory a) internal pure returns (string memory) {
        return string(abi.encodePacked(a));
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function concat(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function concat(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f));
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g));
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g, string memory h) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h));
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g, string memory h, string memory i) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h, i));
    }

    function quote(address value) public pure returns (string memory) {
        return quote(toHex(value));
    }

    function quote(bytes32 value) public pure returns (string memory) {
        return quote(toString(value));
    }

    function quote(string memory value) public pure returns (string memory) {
        return concat("'", value, "'");
    }

    function toHex(address account) public pure returns (string memory) {
        return toHex(abi.encodePacked(account));
    }

    function toHex(uint256 value) public pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(bytes32 value) public pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(bytes memory value) public pure returns (string memory) {
        bytes memory alphabet = "0123456789ABCDEF";

        bytes memory str = new bytes(value.length * 2);
        for (uint i = 0; i < value.length; i++) {
            str[i * 2] = alphabet[uint(uint8(value[i] >> 4))];
            str[1 + i * 2] = alphabet[uint(uint8(value[i] & 0x0f))];
        }
        return string(str);
    }

    function toString(bytes32 value) public pure returns (string memory) {
        uint length = 0;
        for (length; length < 32 && value[length] != 0x0; length++) {
        }
        bytes memory bytesArray = new bytes(length);
        for (uint256 i; i < length; i++) {
            bytesArray[i] = value[i];
        }
        return string(bytesArray);
    }

    function toString(int256 value) public pure returns (string memory) {
        if (value < 0) {
            return concat("-", toString(uint256(- value)));
        }
        return toString(uint256(value));
    }

    function toString(uint256 value) public pure returns (string memory) {
        uint length = 0;
        // Can't take any more digits than Ceiling(log_10(2^256))
        bytes memory bigEndian = new bytes(CEIL_LOG_10_2_256);
        if (value == 0) {
            return "0";
        }
        while (value != 0) {
            uint digit = value % 10;
            bigEndian[length++] = byte(uint8(ASCII_ZERO + digit));
            value /= 10;
        }
        // Convert to little endian and trim on the way
        bytes memory littleEndian = new bytes(length);
        for (uint j = 0; j < length; j++) {
            littleEndian[j] = bigEndian[length - 1 - j];
        }
        return string(littleEndian);
    }

}
