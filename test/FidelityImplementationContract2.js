var chai = require("chai");
var chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
var expect = chai.expect;
var rxjs = require('rxjs');
var timer = rxjs.timer;
var take = rxjs.take;
require('rxjs/operators');



describe("Fidelity Token contract", function () {

  let Token;
  let fidelityToken;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  before(async function () {
	Token = await ethers.getContractFactory('FidelityImplementationContract2');
  });
  
  beforeEach(async function () {
	[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    fidelityToken = await upgrades.deployProxy(Token, [300000], { initializer: 'init' });
	await fidelityToken.deployed();
	await fidelityToken.addStakeholder(owner.address);
  });

  describe("Deployment", function () {

    it("Should set the right owner", async function () {
		expect(await fidelityToken.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
		const ownerBalance = await fidelityToken.balanceOf(owner.address);
		expect((await fidelityToken.totalSupply())._hex).to.equal(ownerBalance._hex);
    });
	
	it("Should add the owner as a stakeholder", async function () {
		expect((await (fidelityToken.isStakeholder(owner.address)))[0]).to.equal(true);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      // Transfer 50 tokens from owner to addr1
      await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr1.address, 50);
      const addr1Balance = await fidelityToken.getFormattedBalance(addr1.address);
      expect(addr1Balance.toString()).to.equal((50).toString());

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr2.address, 50);
      const addr2Balance = await fidelityToken.getFormattedBalance(addr2.address);
      expect(addr2Balance.toString()).to.equal((50).toString());
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await fidelityToken.getFormattedBalance(owner.address);

      // Try to send 1 token from addr1 (0 tokens) to owner (3000000 tokens).
      // `require` will evaluate false and revert the transaction.
      expect(
		fidelityToken.sendTokensFromRetailerToCustomer(addr1.address, owner.address, 1)
      ).to.be.rejectedWith('transfer amount exceeds balance');

      // Owner balance shouldn't have changed.
      expect((await fidelityToken.getFormattedBalance(owner.address)).toString()).to.equal(
        initialOwnerBalance.toString()
      );
    });

    it("Should update balances after transfers", async function () {
      const initialOwnerBalance = await fidelityToken.getFormattedBalance(owner.address);

      // Transfer 100 tokens from owner to addr1.
      await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr1.address, 100);

      // Transfer another 50 tokens from owner to addr2.
      await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr2.address, 50);

      // Check balances.
      const finalOwnerBalance = await fidelityToken.getFormattedBalance(owner.address);
	  const expectedAmount = initialOwnerBalance - 150;
      expect(finalOwnerBalance.toString()).to.equal((initialOwnerBalance - 150).toString());

      const addr1Balance = await fidelityToken.getFormattedBalance(addr1.address);
      expect(addr1Balance.toString()).to.equal((100).toString());

      const addr2Balance = await fidelityToken.getFormattedBalance(addr2.address);
      expect(addr2Balance.toString()).to.equal((50).toString());
	  
    });
	
	it("Test allowance", async function () {
      const initialOwnerBalance = await fidelityToken.getFormattedBalance(owner.address);

      // Transfer 1000 tokens from owner to addr1.
      await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr1.address, 1000);

      // Transfer another 500 tokens from addr1 to addr2.
      await fidelityToken.sendTokensFromRetailerToCustomer(addr1.address, addr2.address, 500);

      
	  
    });
	
  });
  
  describe("Rewards", function () {

    it("Should distribute rewards", async function () {
		await fidelityToken.addStakeholder(addr1.address);
		await fidelityToken.addStakeholder(addr2.address);
		await fidelityToken.addStakeholder(addr3.address);
		
		
		// Transfer another 50 tokens from owner to addr1.
		await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr1.address, 50);
		
		
		// Transfer another 500 tokens from owner to addr2.
		await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr2.address, 500);
		
		
		// Transfer 1000 tokens from owner to addr3.
		await fidelityToken.sendTokensFromRetailerToCustomer(owner.address, addr3.address, 1000);
			
		fidelityToken.distributeRewards();
		
		this.timeout(300000);
		await timer(130000).pipe(take(1)).toPromise();
		
		fidelityToken.distributeRewards();
		
		await timer(10000).pipe(take(1)).toPromise();
		
		const addr1Balance = await fidelityToken.getFormattedBalance(addr1.address);
		expect(addr1Balance.toString()).to.equal((50).toString());
		
		const addr2Balance = await fidelityToken.getFormattedBalance(addr2.address);
		expect(addr2Balance.toString()).to.equal((510).toString());
		
		const addr3Balance = await fidelityToken.getFormattedBalance(addr3.address);
		expect(addr3Balance.toString()).to.equal((1030).toString());
    });
	
  });
});