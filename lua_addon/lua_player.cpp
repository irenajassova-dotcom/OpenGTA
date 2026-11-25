#include "lua_player.h"
#include "localplayer.h"
#include "spritemanager.h"
#include "m_exceptions.h"

namespace OpenGTA {
  namespace Script {

    int Player::getPos(lua_State *L) {
      try {
        Pedestrian & ped = LocalPlayer::Instance().getPed();
        lua_pushnumber(L, ped.pos.x);
        lua_pushnumber(L, ped.pos.y);
        lua_pushnumber(L, ped.pos.z);
        return 3;
      }
      catch (const Util::LocalException & e) {
        /* player not spawned yet */
        lua_pushnil(L);
        return 1;
      }
    }

    int Player::getCash(lua_State *L) {
      lua_pushnumber(L, LocalPlayer::Instance().getCash());
      return 1;
    }

    int Player::addCash(lua_State *L) {
      int v = int(luaL_checknumber(L, 1));
      if (v > 0)
        LocalPlayer::Instance().addCash(uint32_t(v));
      return 0;
    }

    int Player::getWanted(lua_State *L) {
      lua_pushnumber(L, LocalPlayer::Instance().getWantedLevel());
      return 1;
    }

    int Player::setWanted(lua_State *L) {
      int v = int(luaL_checknumber(L, 1));
      if (v < 0) v = 0;
      if (v > 5) v = 5;
      LocalPlayer::Instance().setWanted(v);
      return 0;
    }

    int Player::addWanted(lua_State *L) {
      int v = int(luaL_checknumber(L, 1));
      if (v > 0)
        LocalPlayer::Instance().addWanted(uint32_t(v));
      return 0;
    }

    int Player::getLives(lua_State *L) {
      lua_pushnumber(L, LocalPlayer::Instance().getNumLives());
      return 1;
    }

    int Player::giveLives(lua_State *L) {
      int v = int(luaL_checknumber(L, 1));
      if (v > 0)
        LocalPlayer::Instance().giveLives(uint16_t(v));
      return 0;
    }

#define method(name) {#name, Player::name}
    const luaL_reg Player::methods[] = {
      method(getPos),
      method(getCash),
      method(addCash),
      method(getWanted),
      method(setWanted),
      method(addWanted),
      method(getLives),
      method(giveLives),
      {NULL, NULL}
    };
#undef method

    std::string  Hud::title;
    std::string  Hud::objective;
    std::string  Hud::pagerText;
    unsigned int Hud::pagerTicksLeft = 0;

    int Hud::setTitle(lua_State *L) {
      title = luaL_checkstring(L, 1);
      return 0;
    }

    int Hud::setObjective(lua_State *L) {
      objective = luaL_checkstring(L, 1);
      return 0;
    }

    int Hud::pager(lua_State *L) {
      pagerText = luaL_checkstring(L, 1);
      double secs = lua_isnumber(L, 2) ? lua_tonumber(L, 2) : 4.0;
      pagerTicksLeft = (unsigned int)(secs * 1000.0);
      return 0;
    }

    int Hud::clear(lua_State *L) {
      title.clear();
      objective.clear();
      pagerText.clear();
      pagerTicksLeft = 0;
      return 0;
    }

    void Hud::update(unsigned int elapsed_ms) {
      if (pagerTicksLeft == 0)
        return;
      if (elapsed_ms >= pagerTicksLeft) {
        pagerTicksLeft = 0;
        pagerText.clear();
      }
      else
        pagerTicksLeft -= elapsed_ms;
    }

#define method(name) {#name, Hud::name}
    const luaL_reg Hud::methods[] = {
      method(setTitle),
      method(setObjective),
      method(pager),
      method(clear),
      {NULL, NULL}
    };
#undef method
  }
}
