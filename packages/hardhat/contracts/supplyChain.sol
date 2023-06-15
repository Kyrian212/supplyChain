// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {

    enum ProductStatus { ForSale, Processed, Sold, Shipped }

    struct Product {
        uint productId;
        string productName;
        uint quantity;
        uint price;
        address payable farmer;
        address payable distributor;
        address payable retailer;
        ProductStatus status;
    }



    constructor() {
        owner = msg.sender;  
    }

    address public owner;

    mapping(uint => Product) public products;
    uint public productCount;

    event ProductAdded(uint productId, string productName, uint quantity, uint price, address farmer);
    event ProductProcessed(uint productId, address distributor);
    event ProductSold(uint productId, address retailer);
    event ProductShipped(uint productId, address retailer);

    modifier onlyFarmer(uint _productId) {
        require(msg.sender == products[_productId].farmer, "Only the farmer can perform this action.");
        _;
    }

    modifier onlyDistributor(uint _productId) {
        require(msg.sender == products[_productId].distributor, "Only the distributor can perform this action.");
        _;
    }

    modifier onlyRetailer(uint _productId) {
        require(msg.sender == products[_productId].retailer, "Only the retailer can perform this action.");
        _;
    }

    modifier productExists(uint _productId) {
        require(_productId <= productCount, "Product does not exist.");
        _;
    }

    function addProduct(string memory _productName, uint _quantity, uint _price) public {
        productCount++;
        products[productCount] = Product(productCount, _productName, _quantity, _price, payable(msg.sender), payable(address(0)), payable(address(0)), ProductStatus.ForSale);
        emit ProductAdded(productCount, _productName, _quantity, _price, msg.sender);
    }

    function processProduct(uint _productId) public productExists(_productId) onlyDistributor(_productId) {
        require(products[_productId].status == ProductStatus.ForSale, "Product not available for distribution.");

        products[_productId].distributor = payable(msg.sender);
        products[_productId].status = ProductStatus.Processed;
        emit ProductProcessed(_productId, msg.sender);
    }


   function sellProduct(uint _productId) public productExists(_productId) onlyDistributor(_productId) {
        require(products[_productId].status == ProductStatus.Processed, "Product not available for sale.");

        products[_productId].retailer = payable(msg.sender);
        products[_productId].status = ProductStatus.Sold;
        emit ProductSold(_productId, msg.sender);
    }
    

    function buyProduct(uint _productId) public payable productExists(_productId) {
        require(products[_productId].status == ProductStatus.Processed, "Product not available for sale.");
        require(msg.value >= products[_productId].price, "Insufficient payment.");

        products[_productId].retailer = payable(msg.sender);
        products[_productId].status = ProductStatus.Sold;
        emit ProductSold(_productId, msg.sender);
    }


    function shipProduct(uint _productId) public productExists(_productId) onlyRetailer(_productId) {
        require(products[_productId].status == ProductStatus.Sold, "Product not sold yet.");

        products[_productId].status = ProductStatus.Shipped;
        emit ProductShipped(_productId, msg.sender);
    }
 
}
