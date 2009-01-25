//inputevent.h
//Will Dietz

//Defines the network structs, and the consts used to identify
//what kind of input event this is, and information required to
//recreate it on the server end

/*
    This file is part of iTouchpad.

    iTouchpad is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    iTouchpad is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with iTouchpad.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef _INPUTEVENT_H_
#define _INPUTEVENT_H_

//TODO: does this belong here?
#define PORT 5583

typedef enum
{
	EVENT_TYPE_MOUSE_DOWN,
	EVENT_TYPE_MOUSE_UP,
	EVENT_TYPE_MOUSE_MOVE,
	EVENT_TYPE_MOUSE_SCROLL_MOVE,
	EVENT_TYPE_KEY_DOWN,
	EVENT_TYPE_KEY_UP
} eventtype;

typedef enum
{
	BUTTON_LEFT = 1,
	BUTTON_RIGHT = 2
} buttontype;

typedef struct
{
	int dx;
	int dy;
} mousemove_info;

typedef struct
{
	buttontype button;
} mousebutton_info;

typedef struct
{
	int keycode;
	int modifier;

} keyevent_info;


typedef struct
{
	eventtype event_t;
	union
	{
		mousemove_info move_info;
		mousebutton_info button_info;
		keyevent_info key_info;
	};

} InputEvent, *pInputEvent;


/*-----------------------------------------------------------------------------
 *  KEY CODES:
 *-----------------------------------------------------------------------------*/
//if not defined here, then just encode as a standard ascii.
//we can tackle support for unicode as we come to that--but since we're passing an int
//we coud use utf-32 without much difficulty.

//arrows
static const int kKeyLeft 	= 0xEF51;	/* Move left, left arrow */
static const int kKeyUp		= 0xEF52;	/* Move up, up arrow */
static const int kKeyRight	= 0xEF53;	/* Move right, right arrow */
static const int kKeyDown 	= 0xEF54;	/* Move down, down arrow */

//misc
static const int kKeyBackSpace	= 0xEF08;	/* back space, back char */
static const int kKeyTab		= 0xEF09;
static const int kKeyReturn		= 0xEF0D;	/* Return, enter */
static const int kKeyEscape		= 0xEF1B;
//static const int kKeyDelete		= 0xEFFF;	/* Delete, rubout */


/*-----------------------------------------------------------------------------
 *  Modifiers
 *-----------------------------------------------------------------------------*/
static const int kModShift		= 1 << 0;
static const int kModControl	= 1 << 1;
static const int kModAlt		= 1 << 2;
static const int kModCmd 		= 1 << 3;//AFAIK only valid for a mac
static const int kModFn			= 1 << 4;//free modifier, various usage


#endif // _INPUTEVENT_H_
