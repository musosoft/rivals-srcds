
stock CHAT_SayText2(client, author, const String:message[])
{
    new Handle:buffer = StartMessageOne("SayText2", client);
    if ( buffer != INVALID_HANDLE )
    {
        BfWriteByte(buffer, author);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

stock CHAT_SayText2ToAll(author, const String:message[])
{
    new Handle:buffer = StartMessageAll("SayText2");
    if ( buffer != INVALID_HANDLE )
    {
        BfWriteByte(buffer, author);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

stock CHAT_SayText(client, author, const String:msg[])
{
    if ( !isColorMsg )
    {
        if ( client )
        {
            PrintToChat(client, msg);
            return;
        }
        PrintToChatAll(msg);
        return;
    }
    new String:cmsg[192] = "\x1";
    StrCat(cmsg, sizeof(cmsg), msg);
    if ( client )
    {
        CHAT_SayText2(client, author, cmsg);
        return;
    }
    CHAT_SayText2ToAll(author, cmsg);
    return;
}

stock CHAT_DetectColorMsg()
{
    isColorMsg = GetUserMessageId("SayText2") != INVALID_MESSAGE_ID;
}
