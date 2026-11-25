#ifndef LUA_OGTA_PLAYER_H
#define LUA_OGTA_PLAYER_H

#include <string>
#include "lua.hpp"

namespace OpenGTA {
  namespace Script {

    /* Script access to the local player (used by mission scripts,
     * e.g. scripts/senec98.lua). Registered as the global table 'player'. */
    class Player {
      public:
        static int getPos(lua_State *L);
        static int getCash(lua_State *L);
        static int addCash(lua_State *L);
        static int getWanted(lua_State *L);
        static int setWanted(lua_State *L);
        static int addWanted(lua_State *L);
        static int getLives(lua_State *L);
        static int giveLives(lua_State *L);

        static const luaL_reg methods[];
    };

    /* Minimal mission HUD: a title line, an objective line and a
     * timed pager message. Registered as the global table 'hud'. */
    class Hud {
      public:
        static int setTitle(lua_State *L);
        static int setObjective(lua_State *L);
        static int pager(lua_State *L);
        static int clear(lua_State *L);

        static const luaL_reg methods[];

        static std::string title;
        static std::string objective;
        static std::string pagerText;
        static unsigned int pagerTicksLeft;

        static void update(unsigned int elapsed_ms);
    };
  }
}
#endif
