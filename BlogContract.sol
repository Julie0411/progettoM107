// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract BlogContract {

    struct Account {
        address owner;
        string  username;
        string  bio;
        uint    createdAt;
        bool    exists;
    }

    struct Post {
        uint    postId;
        address author;
        string  title;
        string  content;
        uint    likes;
        uint    createdAt;
        bool    exists;
    }

    struct Comment {
        uint    commentId;
        address author;
        string  text;
        uint    postId;
        uint    createdAt;
    }

    // address  →  Account
    mapping(address => Account) private accounts;

    // postId   →  Post
    mapping(uint => Post) private posts;

    // postId   →  lista di Comment
    mapping(uint => Comment[]) private comments;

    // address  →  lista di postId
    mapping(address => uint[]) private postsByAccount;

    // postId   →  address  →  ha già messo like?
    mapping(uint => mapping(address => bool)) private hasLiked;

    uint private postCount;

    event AccountCreated(address indexed owner, string username);
    event PostCreated(uint indexed postId, address indexed author, string title);
    event PostEdited(uint indexed postId);
    event PostDeleted(uint indexed postId);
    event PostLiked(uint indexed postId, address indexed liker);
    event CommentAdded(uint indexed postId, address indexed author);

    // ─────────────────────────────────────────
    //  MODIFICATORI
    // ─────────────────────────────────────────

    modifier onlyExistingAccount() {
        require(accounts[msg.sender].exists, "Devi prima creare un account.");
        _;
    }

    modifier onlyExistingPost(uint _postId) {
        require(posts[_postId].exists, "Post non trovato.");
        _;
    }

    modifier onlyPostAuthor(uint _postId) {
        require(posts[_postId].author == msg.sender, "Non sei l'autore di questo post.");
        _;
    }

    /// Crea un nuovo account per msg.sender
    function createAccount(string memory _username, string memory _bio) external {
        require(!accounts[msg.sender].exists, "Account gia' esistente.");
        require(bytes(_username).length > 0, "Username non puo' essere vuoto.");

        accounts[msg.sender] = Account({
            owner:     msg.sender,
            username:  _username,
            bio:       _bio,
            createdAt: block.timestamp,
            exists:    true
        });

        emit AccountCreated(msg.sender, _username);
    }

    /// Restituisce i dati di un account dato il suo indirizzo
    function getAccount(address _owner)
        external
        view
        returns (string memory username, string memory bio, uint createdAt)
    {
        require(accounts[_owner].exists, "Account non trovato.");
        Account memory acc = accounts[_owner];
        return (acc.username, acc.bio, acc.createdAt);
    }

    /// Restituisce tutti i postId di un determinato account
    function getPostsByAccount(address _owner) external view returns (uint[] memory) {
        return postsByAccount[_owner];
    }

    /// Crea un nuovo post
    function createPost(string memory _title, string memory _content)
        external
        onlyExistingAccount
    {
        require(bytes(_title).length > 0,   "Il titolo non puo' essere vuoto.");
        require(bytes(_content).length > 0, "Il contenuto non puo' essere vuoto.");

        postCount++;
        uint newId = postCount;

        posts[newId] = Post({
            postId:    newId,
            author:    msg.sender,
            title:     _title,
            content:   _content,
            likes:     0,
            createdAt: block.timestamp,
            exists:    true
        });

        postsByAccount[msg.sender].push(newId);

        emit PostCreated(newId, msg.sender, _title);
    }

    /// Modifica il contenuto di un post (solo l'autore)
    function editPost(uint _postId, string memory _newContent)
        external
        onlyExistingPost(_postId)
        onlyPostAuthor(_postId)
    {
        require(bytes(_newContent).length > 0, "Il contenuto non puo' essere vuoto.");
        posts[_postId].content = _newContent;
        emit PostEdited(_postId);
    }

    /// Elimina un post (solo l'autore)
    function deletePost(uint _postId)
        external
        onlyExistingPost(_postId)
        onlyPostAuthor(_postId)
    {
        posts[_postId].exists = false;
        emit PostDeleted(_postId);
    }

    /// Mette like a un post (una volta sola per indirizzo)
    function likePost(uint _postId)
        external
        onlyExistingAccount
        onlyExistingPost(_postId)
    {
        require(!hasLiked[_postId][msg.sender], "Hai gia' messo like a questo post.");
        hasLiked[_postId][msg.sender] = true;
        posts[_postId].likes++;
        emit PostLiked(_postId, msg.sender);
    }

    /// Restituisce i dettagli di un post
    function getPostDetails(uint _postId)
        external
        view
        onlyExistingPost(_postId)
        returns (
            uint    postId,
            address author,
            string  memory title,
            string  memory content,
            uint    likes,
            uint    createdAt
        )
    {
        Post memory p = posts[_postId];
        return (p.postId, p.author, p.title, p.content, p.likes, p.createdAt);
    }

    /// Restituisce tutti i postId esistenti
    function getAllPosts() external view returns (uint[] memory) {
        // Conta quanti post esistono ancora
        uint count = 0;
        for (uint i = 1; i <= postCount; i++) {
            if (posts[i].exists) count++;
        }

        uint[] memory result = new uint[](count);
        uint idx = 0;
        for (uint i = 1; i <= postCount; i++) {
            if (posts[i].exists) {
                result[idx] = i;
                idx++;
            }
        }
        return result;
    }

    /// Aggiunge un commento a un post
    function addComment(uint _postId, string memory _text)
        external
        onlyExistingAccount
        onlyExistingPost(_postId)
    {
        require(bytes(_text).length > 0, "Il commento non puo' essere vuoto.");

        uint commentId = comments[_postId].length;

        comments[_postId].push(Comment({
            commentId: commentId,
            author:    msg.sender,
            text:      _text,
            postId:    _postId,
            createdAt: block.timestamp
        }));

        emit CommentAdded(_postId, msg.sender);
    }

    /// Restituisce tutti i commenti di un post
    function getComments(uint _postId)
        external
        view
        onlyExistingPost(_postId)
        returns (Comment[] memory)
    {
        return comments[_postId];
    }
}
