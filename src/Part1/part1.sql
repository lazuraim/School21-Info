do
$create_enum$
    begin
        CREATE TYPE TaskStatus AS ENUM ('Start', 'Success', 'Failure');
    exception
        when duplicate_object then null;
    end;
$create_enum$;

-- 2. Peers

create or replace procedure peers() as
$$
begin
    CREATE TABLE Peers
    (
        Nickname varchar PRIMARY KEY,
        Birthday date DEFAULT CURRENT_DATE NOT NULL
    );
end;
$$ language plpgsql;

-- 3. Tasks table

create or replace procedure tasks() as
$$
begin
    CREATE TABLE Tasks
    (
        Title      varchar PRIMARY KEY,
        ParentTask varchar REFERENCES Tasks (Title),
        MaxXP      int NOT NULL DEFAULT 0
    );
end;
$$ language plpgsql;

-- 4. Checks table (1, 3)

create or replace procedure checks() as
$$
begin
    CREATE TABLE Checks
    (
        ID   int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        Peer varchar REFERENCES Peers (Nickname) NOT NULL,
        Task varchar REFERENCES Tasks (Title)    NOT NULL,
        Date date DEFAULT CURRENT_DATE           NOT NULL
    );
end;
$$ language plpgsql;

-- 5. Check table depentions (2, 4)

create or replace procedure xp() as
$$
begin
    CREATE TABLE XP
    (
        ID       int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        CheckID  int REFERENCES Checks (ID),
        XPAmount int NOT NULL
    );
end;
$$ language plpgsql;

create or replace procedure verter() as
$$
begin
    CREATE TABLE Verter
    (
        ID      int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        CheckID int REFERENCES Checks (ID) NOT NULL,
        Status  TaskStatus                 NOT NULL,
        Time    time DEFAULT CURRENT_TIME  NOT NULL
    );
end;
$$ language plpgsql;

-- 6. Peers table depentions (1, 2)

create or replace procedure time_tracking() as
$$
begin
    CREATE TABLE TimeTracking
    (
        ID     int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        Peer   varchar REFERENCES Peers (Nickname),
        Date   date DEFAULT CURRENT_DATE NOT NULL,
        Time   time DEFAULT CURRENT_TIME NOT NULL,
        Status int                       NOT NULL CHECK (Status in (1, 2)),
        CONSTRAINT uk_task_visit UNIQUE (Peer, Date, Time)
    );
end;
$$ language plpgsql;

create or replace procedure recommendations() as
$$
begin
    CREATE TABLE Recommendations
    (
        ID              int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        Peer            varchar REFERENCES Peers (Nickname)                                 NOT NULL,
        RecommendedPeer varchar REFERENCES Peers (Nickname) CHECK (Peer <> RecommendedPeer) NOT NULL
    );
end;
$$ language plpgsql;

create or replace procedure frineds() as
$$
begin
    CREATE TABLE Friends
    (
        ID    int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        Peer1 varchar REFERENCES Peers (Nickname)                        NOT NULL,
        Peer2 varchar REFERENCES Peers (Nickname) CHECK (Peer1 <> Peer2) NOT NULL
    );
end;
$$ language plpgsql;

create or replace procedure transferred_points() as
$$
begin
    CREATE TABLE TransferredPoints
    (
        ID           int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        CheckingPeer varchar REFERENCES Peers (Nickname)                                  NOT NULL,
        CheckedPeer  text REFERENCES Peers (Nickname) CHECK (CheckingPeer <> CheckedPeer) NOT NULL,
        PointsAmount int DEFAULT 0                                                        NOT NULL
    );
end;
$$ language plpgsql;

-- 7. Peers and Checks tables depention (1, 2, 4)

create or replace procedure p2p() as
$$
begin
    CREATE TABLE P2P
    (
        ID           int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
        CheckID      int REFERENCES Checks (ID)          NOT NULL,
        CheckingPeer varchar REFERENCES Peers (Nickname) NOT NULL,
        Status       TaskStatus                          NOT NULL,
        Time         time DEFAULT CURRENT_TIME           NOT NULL,
        CONSTRAINT uk_task_p2p UNIQUE (CheckID, CheckingPeer, Status)
    );
end;
$$ language plpgsql;

create or replace procedure CreateTables() as
$$
begin
    CALL peers();
    CALL tasks();
    CALL checks();
    CALL xp();
    CALL verter();
    CALL time_tracking();
    CALL recommendations();
    CALL frineds();
    CALL transferred_points();
    CALL p2p();
end;
$$ language plpgsql;

create or replace procedure DropTables() as
$$
begin
    DROP TABLE P2P;
    DROP TABLE TransferredPoints;
    DROP TABLE Friends;
    DROP TABLE Recommendations;
    DROP TABLE TimeTracking;
    DROP TABLE Verter;
    DROP TABLE XP;
    DROP TABLE Checks;
    DROP TABLE Tasks;
    DROP TABLE Peers;
end;
$$ language plpgsql;