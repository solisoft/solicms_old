// ============================================================================
// This is an Initialization script for the G-WAN Web Server (http://gwan.ch)
// ----------------------------------------------------------------------------
// init.c: This script is run at startup before G-WAN starts listening so you
//         have a chance to do initiatizations before any traffic can hit the
//         server.
//
//         Do whatever initialization you need to do here, like loading and
//         attaching data or an external database to the G-WAN US_SERVER_DATA
//         persistent pointer.
//
//         The list of the get_env() values that can be used from init.c or
//         main.c is: (get_env() calls with other values will be ignored)
//
//             US_SERVER_DATA
//             SERVER_SOFTWARE
//             SCRIPT_TMO
//             KALIVE_TMO
//             REQUEST_TMO
//             DOWNLOAD_SPEED
//             MIN_READ_SPEED
//             MAX_ENTITY_SIZE
//             USE_WWW_CACHE
//             USE_CSP_CACHE
//
//         Note that, unlike the optional Maintenance script (started later
//         and run in its own thread so it can either stop or loop forever),
//         this init.c script MUST return to let G-WAN start listening.
//
//         To avoid running the optional init.c script, rename it to anything
//         else than 'init.c' ('init.c_' used by default, is fine).
// ============================================================================
#include "gwan.h"  // G-WAN API
#include <stdio.h> // puts()

int main(int argc, char *argv[])
{
   puts("  G-WAN has run the Intitialization script 'init.c' stored in\n"
        "  the gwan executable directory. Unlike the Maintenance script\n"
        "  ('main.c'), the 'init.c' script must return to let G-WAN run.\n");

   // -------------------------------------------------------------------------
   // US_SERVER_DATA is a global pointer initialized to NULL so you can
   // setup it before the G-WAN server has launched worker threads, and
   // before it is listening
   //
   // typedef struct // an example of user-defined data structure:
   // {
   //    kv_t *kv;   // a Key-Value store
   //    char *blah; // a string
   //    int   val;  // a counter
   // } data_t;
   //data_t **data = (data_t**)get_env(argv, US_SERVER_DATA);
   //
   // attach your user-defined structure
   // if(data)
   // {
   //    data[0] = (data_t*)calloc(1, sizeof(data_t));
   //    load any data/code you want to use later from handlers/servlets
   //    ...
   // }


   u8 *www_mini = (u8*)get_env(argv, USE_MINIFYING);
   if(www_mini)
   {
      *www_mini = 0;
      puts("> disable minifying");
   }
   // -------------------------------------------------------------------------
   // USE_WWW_CACHE can be used to enable automatic caching of static files:
   //
   u8 *www_cache = (u8*)get_env(argv, USE_WWW_CACHE);
   if(www_cache)
   {
      *www_cache = 0;
      puts("> enabled www cache");
   }

   // -------------------------------------------------------------------------
   // USE_CSP_CACHE can be used to enable automatic caching of slow servlets.
   //
   u8 *csp_cache = (u8*)get_env(argv, USE_CSP_CACHE);
   if(csp_cache)
   {
      *csp_cache = 0;
      puts("> enabled csp cache");
   }

   // -------------------------------------------------------------------------
   // the QUERY_CHAR character can be chosen from the following set:
   //  - _ . ! ~ * ' ( )
   // (see RFC 2396, section "2.3. Unreserved Characters")
   //
   // u8 *query_char = (u8*)get_env(argv, QUERY_CHAR);
   // if(query_char)
   // {
   //    *query_char = '!'; // "/!hello.c" instead of "/?hello.c"
   //    puts("> changed query_character");
   // }

   // -------------------------------------------------------------------------
   // DEFAULT_LANG lets you change the default language which can be queried
   // without providing a file extension: "/?hello" instead of "/?hello.c"
   // (defaults to LG_C: ANSI C)
   // LG_C, LG_CPP, LG_JAVA, etc. are defined in /gwan/include/gwan.h
   // and in http://gwan.com/api#env
   //
   //u8 *lang = (u8*)get_env(argv, DEFAULT_LANG);
   //if(lang)
   // {
   //    *lang = LG_CPP; // use "/?hello" instead of "/?hello.cpp"
   //    puts("> changed default_language to CPP");
   // }

   return 0; // 0:OK, if( < 0) then G-WAN will stop with exit(-1).
}
// ============================================================================
// End of Source Code
// ============================================================================
