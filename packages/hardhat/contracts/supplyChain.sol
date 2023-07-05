// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    
    enum ProductStatus { ForSale, Processed, Sold, Shipped }

    struct Product {
        uint256 productId;
        string productName;
        uint256 quantity;
        uint256 price;
        address payable farmer;
        address payable distributor;
        address payable retailer;
        ProductStatus status;
    }

    // Define roles
    enum Role { Owner, Farmer, Distributor, Retailer }

    // Define actors
    struct User {
        address id;
        Role role;
        string name;
    }

    address public owner;
    mapping(address => Role) public roles;
    mapping(uint256 => Product) public products;
    uint256 public productCount;

    event ProductAdded(uint256 productId, string productName, uint256 quantity, uint256 price, address farmer);
    event ProductProcessed(uint256 productId, address distributor);
    event ProductSold(uint256 productId, address retailer);
    event ProductShipped(uint256 productId, address retailer);

    modifier onlyFarmer(uint256 _productId) {
        require(msg.sender == products[_productId].farmer, "Only the farmer can perform this action.");
        _;
    }

    modifier onlyDistributor(uint256 _productId) {
        require(msg.sender == products[_productId].distributor, "Only the distributor can perform this action.");
        _;
    }

    modifier onlyRetailer(uint256 _productId) {
        require(msg.sender == products[_productId].retailer, "Only the retailer can perform this action.");
        _;
    }

    modifier productExists(uint256 _productId) {
        require(_productId <= productCount, "Product does not exist.");
        _;
    }

    constructor() {
        owner = msg.sender;
        roles[owner] = Role.Owner;  
    }

    function assignRole(address user, Role role) public {
        require(msg.sender == owner, "Only the contract owner can assign roles");
        roles[user] = role;
    }

    function addProduct(string memory _productName, uint256 _quantity, uint256 _price) public {
        productCount++;
        products[productCount] = Product(productCount, _productName, _quantity, _price, payable(msg.sender), payable(address(0)), payable(address(0)), ProductStatus.ForSale);
        emit ProductAdded(productCount, _productName, _quantity, _price, msg.sender);
    }

    function processProduct(uint256 _productId) public productExists(_productId) onlyDistributor(_productId) {
        require(products[_productId].status == ProductStatus.ForSale, "Product not available for distribution.");

        products[_productId].distributor = payable(msg.sender);
        products[_productId].status = ProductStatus.Processed;
        emit ProductProcessed(_productId, msg.sender);
    }

    function sellProduct(uint256 _productId) public productExists(_productId)  onlyRetailer(_productId){
        require(products[_productId].status == ProductStatus.Processed, "Product not available for sale.");

        products[_productId].retailer = payable(msg.sender);
        products[_productId].status = ProductStatus.Sold;
        emit ProductSold(_productId, msg.sender);
    }

    function buyProduct(uint256 _productId) public payable productExists(_productId) {
        require(products[_productId].status == ProductStatus.ForSale, "Product not available for sale.");
        require(msg.value >= products[_productId].price, "Insufficient payment.");

        products[_productId].retailer = payable(msg.sender);
        products[_productId].status = ProductStatus.Sold;
        emit ProductSold(_productId, msg.sender);
    }

    function shipProduct(uint256 _productId) public productExists(_productId) onlyRetailer(_productId) {
        require(products[_productId].status == ProductStatus.Sold, "Product not sold yet.");

        products[_productId].status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }
}


