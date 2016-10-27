// Prevent double included , its important
#if defined _fragradio_included
  #endinput
#endif
#define _fragradio_included


/**
 * Check if current player is opt into fragradio already
 *
 * @param client    Client index
 * @return        True when user is listening, false otherwise
 */
native bool FR_IsPlayerListening(int client);