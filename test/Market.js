
const Market = artifacts.require('Market')

contract('Market', (accounts) => {
    let market = null
    before(async ()=>{
        market = await Market.deployed()
    })
    it('Should show the correct balance', async ()=>{
        await market.mint(10,100,{from: accounts[0]})
        const balance = await market.balanceOf(accounts[0], 10)
        assert(balance.toNumber() === 100)
    })

    it('Should show the correct balance of a batch', async ()=>{
        await market.mint(10,100,{from: accounts[0]})
        await market.mint(20,110,{from: accounts[1]})
        await market.mint(30,120,{from: accounts[2]})
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
            assert(e.message.indexOf("revert") >= 0, "not owner or approved")
        }    
        await market.safeTransferFrom(accounts[0],accounts[1],10,45, '0x0', {from: accounts[0]})
        const balance1 = await market.balanceOf(accounts[0],10)
        const balance2 = await market.balanceOf(accounts[1],10)
        assert(balance1.toNumber() === 55)
        assert(balance2.toNumber() === 45)
    })

    it('Should make a safe batch transfer from', async ()=>{
        await market.burn(10, {from: accounts[1]})
        await market.burn(20, {from: accounts[1]})
        await market.mint(10, 100,{from: accounts[0]})
        await market.mint(20, 100,{from: accounts[0]})
        await market.safeBatchTransferFrom(accounts[0],accounts[1],[10,20],[45,50], '0x0', {from: accounts[0]})
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
        await market.setApprovalForAll(accounts[1], true,{from: accounts[0]})
        const isAppr = await market.isApprovedForAll(accounts[0],accounts[1])
        assert(isAppr)
        await market.safeTransferFrom(accounts[0],accounts[1],10,45, '0x0', {from: accounts[1]})
        const balance = await market.balanceOf(accounts[1],10)
        assert(balance.toNumber() === 45)
    })

})