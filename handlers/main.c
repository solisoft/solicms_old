// ============================================================================
// Handler C script for the G-WAN Web Application Server (http://trustleap.ch/)
// ----------------------------------------------------------------------------
// main.c: make RESTFUL dynamic URIs (without URI rewriting)
// ============================================================================
//#pragma debug   // uncomment to get symbols/line numbers in crash reports

#include "gwan.h" // G-WAN exported functions

int init(int argc, char *argv[])
{
   // in this handler, we do not define which handler states we want to be 
   // notified since we do not want to receive notifications at all

   // to replace the '?' query character, use any character among: -_.!~*'()
   // (RFC 2396 Section 2.3 "Unreserved Characters")
   // 

   
   u8 *query_char = (u8*)get_env(argv, QUERY_CHAR);
   *query_char = '!'; // we must use "/!helloc.c" instead of "/?helloc.c"

   // to avoid script extensions in URIs, we define a default language
   // (the only language that can be invoked without a file extension)
   // NOTE: by default, DEFAULT_LANG = LG_C;
   //
   u8 *default_lang = (u8*)get_env(argv, DEFAULT_LANG);
   *default_lang = LG_RUBY; // we can use "/!hello" instead of "/!helloc.cpp"
   
  u32 *states = (u32*)get_env(argv, US_HANDLER_STATES);
  *states = (1 << HDL_AFTER_READ);
  return 0;
}
// ----------------------------------------------------------------------------
// must exist, but will never be called since we did not define notifications
// ----------------------------------------------------------------------------
void clean(int argc, char *argv[])
{}
// ----------------------------------------------------------------------------
// must exist, but will never be called since we did not define notifications
// ----------------------------------------------------------------------------
int main(int argc, char *argv[])
{

  const int state = (long)argv[0];
  if(state != HDL_AFTER_READ)
    return 255;

  xbuf_t *read_xbuf = (xbuf_t*)get_env(argv, READ_XBUF);
  //printf("req_1: %s\n", read_xbuf->ptr);
  xbuf_replfrto(read_xbuf, read_xbuf->ptr, read_xbuf->ptr + 16, " / ", " /!page ");
  xbuf_replfrto(read_xbuf, read_xbuf->ptr, read_xbuf->ptr + 16, " /!page/ ", " /!page ");
  //xbuf_repl(read_xbuf, " GET / HTTP ", " GET /!page HTTP ");
  //xbuf_repl(read_xbuf, " GET /!page/ HTTP ", " GET /!page HTTP ");
  //printf("req_2: %s\n-------------------\n\n", read_xbuf->ptr);


   return(255); // continue G-WAN's default execution path
}
// ============================================================================
// End of Source Code
// ============================================================================
