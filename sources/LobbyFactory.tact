import "@stdlib/deploy";
import "@stdlib/ownable";
import "./Lobby";

message CreateLobby {
    maxPlayers: Int as uint8;
}



contract LobbyFactory with Deployable{
    owner: Address;
    lastID: Int as int32;
    lobbies: map<Int, Address>;
    controllerAddress: Address = address("EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N");

    init(owner: Address) {
        self.owner = owner;
        self.lastID = 0;
        self.lobbies = emptyMap();
    }
    receive(msg: CreateLobby) {
        let ctx = context();
        require(ctx.value >= ton("1"), "Must send 1 TON to cover deploy cost");
        
        let init = initOf Lobby(
            msg.maxPlayers,
            ctx.sender,
            self.controllerAddress 
        );

        deploy(DeployParameters {
            value: ton("1"),
            init: init,
            body: "create-lobby".asComment(),
        });
        self.lobbies.set(self.lastID, contractAddress(init));
        self.lastID += 1;

    }

    get fun getLobby(id: Int): Address? {
        return self.lobbies.get(id);
    }

}