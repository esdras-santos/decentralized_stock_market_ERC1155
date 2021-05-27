
const Market = artifacts.require('Market')

contract('Market', (accounts) => {
    let market = null
    before(async ()=>{
        market = await Market.deployed()
    })

    it("Test the panic button", async ()=>{ 
        try{
            await market.panic({from: accounts[1]})
        }catch(e){
            assert(e.message.indexOf("revert") >= 0, "only the admin can make that")
        }
        await market.mint(10, 100,{from: accounts[0]})
        // in this case account 0 is the admin.
        //turning on the panic button.
        await market.panic({from: accounts[0]})
        try{
            await market.safeTransferFrom(accounts[0],accounts[1],10,45, '0x0', {from: accounts[0]})
        }catch(e){
            assert(e.message.indexOf("revert") >= 0, "panic button is activated")
        }
        //turning off the punic button
        await market.panic({from: accounts[0]})
    })

    it('Should show the correct balance', async ()=>{
        await market.mint(10,100,{from: accounts[0]})
        const balance = await market.balanceOf(accounts[0], 10)
        assert(balance.toNumber() === 100)
    })

    it('Should show the correct balance of a batch', async ()=>{
        //begin set balances for test
        await market.mint(10,100,{from: accounts[0]})
        await market.mint(20,110,{from: accounts[1]})
        await market.mint(30,120,{from: accounts[2]})
        //end set balances for test
        try{  
            await market.balanceOfBatch([accounts[0],accounts[1],accounts[2]], [10,20,30,40])
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "ids length is larger than addresses length")
        }
        const balance = await market.balanceOfBatch([accounts[0],accounts[1],accounts[2]], [10,20,30])
        const balances = balance.map(id => id.toNumber())
        assert.deepEqual(balances, [100,110,120])
    })

    it('Should make a safe transfer from', async ()=>{
        await market.mint(10, 100,{from: accounts[0]})
        try{       
            await market.safeTransferFrom(accounts[0],accounts[1],10,145, '0x0', {from: accounts[0]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "value larger than balance")
        } 
        try{       
            await market.safeTransferFrom(accounts[0],accounts[1],10,145, '0x0', {from: accounts[1]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "not owner neither approved")
        }    
        const receipt = await market.safeTransferFrom(accounts[0],accounts[1],10,45, '0x0', {from: accounts[0]})
        assert.equal(receipt.logs.length, 1, "trigger event")
        assert.equal(receipt.logs[0].event, "TransferSingle", "should be the the transfersingle event")
        assert.equal(receipt.logs[0].args._operator, accounts[0], "the operator")
        assert.equal(receipt.logs[0].args._from, accounts[0], "owner of the tokens")
        assert.equal(receipt.logs[0].args._to, accounts[1], "receipt of the tokens")
        assert.equal(receipt.logs[0].args._id, 10, "id of tokens sended")
        assert.equal(receipt.logs[0].args._value, 45, "amount of tokens sended")
        const balance1 = await market.balanceOf(accounts[0],10)
        const balance2 = await market.balanceOf(accounts[1],10)
        assert(balance1.toNumber() === 55)
        assert(balance2.toNumber() === 45)
    })

    it('Should make a safe batch transfer from', async ()=>{
        // begin set balances for test
        await market.burn(10, {from: accounts[1]})
        await market.burn(20, {from: accounts[1]})
        await market.mint(10, 100,{from: accounts[0]})
        await market.mint(20, 100,{from: accounts[0]})
        // and set balances 
        try{       
            await market.safeBatchTransferFrom(accounts[0],accounts[1],[10,20,30],[45,50], '0x0', {from: accounts[0]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "ids length is larger than addresses length")
        }
        try{       
            await market.safeBatchTransferFrom(accounts[0],accounts[1],[10,20],[45,50], '0x0', {from: accounts[1]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "not the owner or approved")
        } 
        try{       
            await market.safeBatchTransferFrom(accounts[0],accounts[1],[10,20],[145,150], '0x0', {from: accounts[0]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "amounts larger than the balances")
        }

        const receipt = await market.safeBatchTransferFrom(accounts[0],accounts[1],[10,20],[45,50], '0x0', {from: accounts[0]})
        assert.equal(receipt.logs.length, 1, "trigger event")
        assert.equal(receipt.logs[0].event, "TransferBatch", "should be the transferbatch event")
        assert.equal(receipt.logs[0].args._operator, accounts[0], "the operator")
        assert.equal(receipt.logs[0].args._from, accounts[0], "owner of the tokens")
        assert.equal(receipt.logs[0].args._to, accounts[1], "receipt of the tokens")
        const ids = receipt.logs[0].args._ids.map(id => id.toNumber())
        assert.deepEqual(ids, [10,20])
        const values = receipt.logs[0].args._values.map(id => id.toNumber())
        assert.deepEqual(values, [45,50])
        
        const balance1 = await market.balanceOfBatch([accounts[0],accounts[1]],[10,10])
        const balances1 = balance1.map(id => id.toNumber())
        const balance2 = await market.balanceOfBatch([accounts[0],accounts[1]],[20,20])
        const balances2 = balance2.map(id => id.toNumber())
        assert.deepEqual(balances1, [55,45])
        assert.deepEqual(balances2, [50, 50])
    })

    it('should approve an operator', async () =>{
        await market.burn(10,{from:accounts[1]})
        await market.mint(10, 100,{from: accounts[0]})
        try{       
            await market.setApprovalForAll(accounts[1], true,{from: accounts[1]})
        } catch(e){
            assert(e.message.indexOf("revert") >= 0, "the owner cannot be the operator")
        } 
        const receipt = await market.setApprovalForAll(accounts[1], true,{from: accounts[0]})
        assert.equal(receipt.logs.length, 1, "trigger event")
        assert.equal(receipt.logs[0].event, "ApprovalForAll", "should be the approvalforall event")
        assert.equal(receipt.logs[0].args._owner, accounts[0], "owner of the tokens")
        assert.equal(receipt.logs[0].args._operator, accounts[1], "the operator")
        assert.equal(receipt.logs[0].args._approved, true, " is approved")
        
        const isAppr = await market.isApprovedForAll(accounts[0],accounts[1])
        assert(isAppr)
        await market.safeTransferFrom(accounts[0],accounts[1],10,45, '0x0', {from: accounts[1]})
        const balance = await market.balanceOf(accounts[1],10)
        assert(balance.toNumber() === 45)
    })

    //the balances need to be tested carefully
    it("Should shutdown the contract", async ()=>{
        try{
            await market.shutDown({from: accounts[1]})
        }catch(e){
            assert(e.message.indexOf("revert") >= 0, "only the admin can make that")
        }
        try{
            await market.shutDown({from: accounts[0]})
        }catch(e){
            assert(e.message.indexOf("revert") >= 0, "is not in emergency")
        }
        // in this case account 0 is the admin
        await market.panic({from: accounts[0]})

        //TEST THE FUCKING BALANCES YOUR DUMB
        await market.shutDown({from:accounts[0]})
    })

})