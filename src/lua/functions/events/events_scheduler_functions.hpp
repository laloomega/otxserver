/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#ifndef SRC_GAME_SCHEDUNLING_EVENTS_SCHEDULER_FUNCTIONS_HPP_
#define SRC_GAME_SCHEDUNLING_EVENTS_SCHEDULER_FUNCTIONS_HPP_

#include <set>

#include "lua/scripts/lua_environment.hpp"
#include "lua/scripts/luascript.h"

extern LuaEnvironment g_luaEnvironment;

class EventsSchedulerFunctions final : private LuaScriptInterface {
	public:
		static void init(lua_State* L) {
			registerTable(L, "EventsScheduler");

			registerMethod(L, "EventsScheduler", "getEventSLoot", EventsSchedulerFunctions::luaEventsSchedulergetEventSLoot);
			registerMethod(L, "EventsScheduler", "getEventSSkill", EventsSchedulerFunctions::luaEventsSchedulergetEventSSkill);
			registerMethod(L, "EventsScheduler", "getEventSExp", EventsSchedulerFunctions::luaEventsSchedulergetEventSExp);
			registerMethod(L, "EventsScheduler", "getSpawnMonsterSchedule", EventsSchedulerFunctions::luaEventsSchedulergetSpawnMonsterSchedule);
		}

	private:
		static int luaEventsSchedulergetEventSLoot(lua_State* L);
		static int luaEventsSchedulergetEventSSkill(lua_State* L);
		static int luaEventsSchedulergetEventSExp(lua_State* L);
		static int luaEventsSchedulergetSpawnMonsterSchedule(lua_State* L);
};

#endif // SRC_GAME_SCHEDUNLING_EVENTS_SCHEDULER_FUNCTIONS_HPP_
