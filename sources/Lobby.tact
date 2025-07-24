import "@stdlib/deploy";
import "@stdlib/ownable";

const MinForStorage: Int = ton("0.02");
message OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

struct Player {
    address: Address;
    nft: Address;
}

message ResolveGame {
    winner: Address;
}

message Forfeit {
    player: Address;
}

contract Lobby with Deployable{
    owner: Address;
    maxPlayers: Int as uint8;
    players: map<Int, Player>;
    playerCount: Int as uint8;
    ended: Bool;
    controller: Address;
    init(
        maxPlayers: Int,
        owner: Address,
        controller: Address
    ){
        self.maxPlayers = maxPlayers;
        self.owner = owner;
        self.playerCount = 0;
        self.ended = false;
        self.players = emptyMap();
        self.controller = controller;
    }

    receive(msg: OwnershipAssigned) {
        let ctx = context();
        require(!self.ended, "Game ended");
        require(self.playerCount < self.maxPlayers, "Lobby full");
        let fullBody = inMsg();
        require(fullBody.bits() >= 32, "Invalid join payload");
        let prefix = fullBody.preloadUint(32);
        require(prefix == 0, "Expected text message");

        fullBody.skipBits(32);
        let joinPayload = fullBody;
        require(joinPayload.hash() == "join".asSlice().hash(), "Invalid join payload");
        self.players.set(self.playerCount, Player { address: msg.prevOwner, nft: ctx.sender });
        self.playerCount += 1;
    }

    receive(msg: ResolveGame) {
        let ctx = context();
        require(!self.ended, "Game already ended");
        require(ctx.sender == self.controller, "Only game controller can resolve");
        foreach (i, p in self.players) {
            let transferBody = Transfer {
                queryId: 0,
                newOwner: msg.winner,
                responseDestination: msg.winner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
            }.toCell();
            send(SendParameters{
                to: p.nft,
                value: ton("0.05"),
                mode: SendRemainingValue,
                bounce: true,
                body: transferBody
            });
        }
        let refund = myBalance() - MinForStorage;
        require(refund >= ton("1"), "Not enough for refund");
        send(SendParameters {
            to: self.owner,
            value: ton("1"),
            mode: SendRemainingValue,
            bounce: true,
            body: "refund".asComment()
        });
        self.ended = true;
    }

    get fun isEnded(): Bool {
        return self.ended;
    }

    get fun currentPlayers(): Int {
        return self.playerCount;
    }


}