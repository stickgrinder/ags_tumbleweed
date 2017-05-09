AGSScriptModule    Authors named in header file 9Verb GUI functions 9-Verb MI-Style 1.5.4 �	 // Gui Script
// ================================ OPTIONS ===============================================
// ============================= EDIT FROM HERE ===========================================

// Setup the default Language (only affects the provided GUIs) 
// Unhandled events can directly be changed in the function Unhandled()

// Currently supported languages:
// eLangEN (English)
// eLangDE (German)
// eLangES (Spanish)
// eLangFR (French)
// eLangIT (Italian)
// eLangPT (Portuguese)

int lang = eLangEN;           

int
ActionLabelColorNormal          = 15219,  // colour used in action bar
ActionLabelColorHighlighted     = 38555,  // highlighted colour used in action bar
invUparrowONsprite              = 124,    // sprite slot of the upper inv arrow / normal
invUparrowOFFsprite             = 154,    // sprite slot of the upper inv arrow / disabled
invUparrowHIsprite              = 137,    // sprite slot of the upper inv arrow / highlighted
invDownarrowONsprite            = 128,    //  "   "      "      lower   "   "       
invDownarrowOFFsprite           = 155,    //  "   "      "      lower   "   "
invDownarrowHIsprite            = 141,    //  "   "      "      lower   "   "
walkoffscreen_offset            = 30,     // offset used by WalkOffScreen and exit extensions
cursorspritenumber              = 19,     // used for semi-blockable movement
blankcursorspritenumber         = 29;     // used for semi-blockable movement
bool approachCharInteract       = true;   // walk to character before starting interaction
bool openDoorDoubleclick        = true;   // doubleclick on open doors changes room instantly
bool disableDoubleclick         = false;  // disable doubleclick entirely
bool NPC_facing_player          = false;  // Non playable characters are facing 
                                          // the player before talk-to and give-to
bool oldschool_inv_clicks       = false;  // turned on: right-click on inv items is lookat
                                          // turned off: right-click on inv items is use
bool objHotTalk                 = false;  // Talk to Objects and Hotspots
               
// You can define Audioclips, which are being used in the doorscripts
#ifndef USE_OBJECT_ORIENTED_AUDIO
// In AGS 3.1 you have to assign a number:
//   openDoorSound = 15;
int openDoorSound   = 0, 
    closeDoorSound  = 0, 
    unlockDoorSound = 0;
#endif

#ifdef USE_OBJECT_ORIENTED_AUDIO
// In AGS 3.2 you do it this way:
//   Audioclip *openDoorSound = aDoorsound;
AudioClip*  openDoorSound,  
            closeDoorSound, 
            unlockDoorSound;    
#endif

// ============================= EDIT UNTIL HERE ===========================================


// ========================== variables (not to edit) ======================================

String madetext;          // String that is shown in the action bar
String numbers;           // used by getInteger() to convert strings
String door_strings[6];   // default messages for the door script

int global_action;        // containing the current clicked action
int default_action;       // default action (most likely walk-to)
int alternative_action;   // right-click action
int used_action;          // used_action = global_action, if not cancelled
int GSagsusedmode;        // on_mouse_click -> unhandled_event
int GSloctype;            // the result of GetLocationType
int GSlocid;              // on_mouse_click ->
int GScancelable;         // MovePlayer
String GSlocname;         // on_mouse_click -> unhandled_event
String GSinvloc;          // locationname>extension
String SHOWNlocation;     // location translated
String location;          // The location name underneath the cursor
bool player_frozen;       // player can't move
bool disabled_gui;        // GUI disabled
int door_state[MAX_DOORS];              // Array for the door script
int action_button[A_COUNT_];            // Array containing the verb button Ids
int action_button_normal[A_COUNT_];     // contains the verb button sprites
int action_button_highlight[A_COUNT_];  // Contains the highlighted verb button sprites
int button_action[A_COUNT_];            // Array containg the related actions like eGA_LookAt

String tresult;           // translated result of the action mode, eg. "Look at %s"
String act_object;        // action_object - object used in action
String item;              // inventory item to be used or given 
int GStopsaveitem = 0;    // top savegame element of the save GUI
int listBoxGap;           // used in the save-game dialog to determine a list-item's height
int dc_speed;             // double click speed, set in the game start section


int action_l_keycode[A_COUNT_]; // lower case keycodes for the verbs
int action_u_keycode[A_COUNT_]; // upper case keycodes for the verbs
InventoryItem*ItemGiven;        // Item given to a character
char key_l_yes, key_u_yes, key_l_no, key_u_no; // translated keys for yes and no
bool doubleclick;               // doubleclick occured
bool timer_run;                 // is doubleclick timer running
int timer_click;                // double click timer



// ============================= Helper functions ===========================================
function set_door_state(int door_id, int value) {
  door_state[door_id] = value;
}

int get_door_state(int door_id) {
  return door_state[door_id];
}

function init_object (int door_id, int obj){
  if (get_door_state(door_id) == 1) {
    object[obj].Visible=true;
    object[obj].Clickable=false;
  }
  else { 
    object[obj].Visible=false;
    object[obj].Clickable=false;
  }
}

int Absolute(int value) {
  if (value<0) return -value;
  return value;
}

int Offset(int point1, int point2) {
  return Absolute(point1 - point2);
}

int getButtonAction(int action) {
  return button_action[action];
}

function disable_gui()
{
  disabled_gui=true;
  gMaingui.Visible=false;
  gAction.Visible=false;
}

function enable_gui()
{
  disabled_gui=false;
  gMaingui.Visible=true;
  gAction.Visible=true;
  Wait(1);
}

bool is_gui_disabled() {
  return disabled_gui;
}

function set_double_click_speed(int speed){
  dc_speed = speed;
}


// ============================= verb action functions ===========================================
function TranslateAction(int action, int tr_lang) {
  if (tr_lang == eLangDE) {
    if (action == eMA_WalkTo)   tresult="Gehe zu %s";
    else if (action == eGA_LookAt)   tresult="Schau %s an";
    else if (action == eGA_TalkTo)   tresult="Rede mit %s";
    else if (action == eGA_GiveTo) {
      if (item.Length>0)             tresult="Gib !s an %s";
      else                           tresult="Gib %s";
    }
    else if (action == eGA_PickUp)   tresult="Nimm %s";
    else if (action == eGA_Use) {
      if (item.Length>0)             tresult="Benutze !s mit %s";
      else                           tresult="Benutze %s";
    }
    else if (action == eGA_Open)     tresult="�ffne %s";
    else if (action == eGA_Close)    tresult="Schlie�e %s";
    else if (action == eGA_Push)     tresult="Dr�cke %s";
    else if (action == eGA_Pull)     tresult="Ziehe %s";
    else tresult=" ";   
  }
  else if (tr_lang == eLangES) {
    if (action == eMA_WalkTo)   tresult="Ir a %s";
    else if (action == eGA_LookAt)   tresult="Mirar %s";
    else if (action == eGA_TalkTo)   tresult="Hablar con %s";
    else if (action == eGA_GiveTo) {
      if (item.Length>0)             tresult="Dar !s a %s";
      else                           tresult="Dar %s";
    }
    else if (action == eGA_PickUp)   tresult="Coger %s";
    else if (action == eGA_Use) {
      if (item.Length>0)             tresult="Usar !s con %s";
      else                           tresult="Usar %s";
    }
    else if (action == eGA_Open)     tresult="Abrir %s";
    else if (action == eGA_Close)    tresult="Cerrar %s";
    else if (action == eGA_Push)     tresult="Empujar %s";
    else if (action == eGA_Pull)     tresult="Tirar de %s";
    else tresult=" ";    
  }
  else if (tr_lang == eLangFR) {
    if (action == eMA_WalkTo)   tresult="Aller vers %s";
    else if (action == eGA_LookAt)   tresult="Regarder %s";
    else if (action == eGA_TalkTo)   tresult="Parler � %s";
    else if (action == eGA_GiveTo) {
      if (item.Length>0)             tresult="Donner !s � %s";
      else                           tresult="Donner %s";
    }
    else if (action == eGA_PickUp)   tresult="Prendre %s";
    else if (action == eGA_Use) {
      if (item.Length>0)             tresult="Utiliser !s sur %s";
      else                           tresult="Utiliser %s";
    }
    else if (action == eGA_Open)     tresult="Ouvrir %s";
    else if (action == eGA_Close)    tresult="Fermer %s";
    else if (action == eGA_Push)     tresult="Pousser %s";
    else if (action == eGA_Pull)     tresult="Tirer %s";
    else tresult=" "; 
  }  
  else if (tr_lang == eLangIT) {
    if (action == eMA_WalkTo)   tresult="Vai a %s";
    else if (action == eGA_LookAt)   tresult="Esamina %s";
    else if (action == eGA_TalkTo)   tresult="Parla con %s";
    else if (action == eGA_GiveTo) {
    if (item.Length>0)               tresult="Dai !s a %s";
    else                             tresult="Dai %s";
    }
    else if (action == eGA_PickUp)   tresult="Raccogli %s";
    else if (action == eGA_Use) {
    if (item.Length>0)               tresult="Usa !s con %s";
    else                             tresult="Usa %s";
    }
    else if (action == eGA_Open)     tresult="Apri %s";
    else if (action == eGA_Close)    tresult="Ferma %s";
    else if (action == eGA_Push)     tresult="Premi %s";
    else if (action == eGA_Pull)     tresult="Tira %s";
    else tresult=" "; 
  }
  else if (tr_lang == eLangPT) {
    if (action == eMA_WalkTo)   tresult="Ir para %s";
    else if (action == eGA_LookAt)   tresult="Olhar para %s";
    else if (action == eGA_TalkTo)   tresult="Falar com %s";
    else if (action == eGA_GiveTo) {
    if (item.Length>0)               tresult="Dar !s a %s";
    else                             tresult="Dar %s";
    }
    else if (action == eGA_PickUp)   tresult="Apanhar %s";
    else if (action == eGA_Use) {
    if (item.Length>0)               tresult="Usar !s com %s";
    else                             tresult="Usar %s";
    }
    else if (action == eGA_Open)     tresult="Abrir %s";
    else if (action == eGA_Close)    tresult="Fechar %s";
    else if (action == eGA_Push)     tresult="Empurrar %s";
    else if (action == eGA_Pull)     tresult="Puxar %s";
    else tresult=" "; 
  }   
  else {
    if (action == eMA_WalkTo)   tresult="Go to %s";
    else if (action == eGA_LookAt)   tresult="Look at %s";
    else if (action == eGA_TalkTo)   tresult="Talk to %s";
    else if (action == eGA_GiveTo) {
      if (item.Length>0)             tresult="Give !s to %s";
      else                           tresult="Give %s";
    }
    else if (action == eGA_PickUp)   tresult="Pick up %s";
    else if (action == eGA_Use) {
      if (item.Length>0)             tresult="Use !s with %s";
      else                           tresult="Use %s";
    }
    else if (action == eGA_Open)     tresult="Open %s";
    else if (action == eGA_Close)    tresult="Close %s";
    else if (action == eGA_Push)     tresult="Push %s";
    else if (action == eGA_Pull)     tresult="Pull %s";
    else tresult=" ";    
  }
  // fill object and item into action template
  tresult=GetTranslation(tresult);
  int ip=tresult.IndexOf("!s");
  if (ip>=0) {
    int op=tresult.Contains("%s");
    tresult=tresult.ReplaceCharAt(ip, '%');
    if (ip<op) tresult=String.Format(tresult, item, act_object);
    else       tresult=String.Format(tresult, act_object, item);
  }
  else         tresult=String.Format(tresult, act_object);
}

bool isAction(Action test_action) {
  return global_action == test_action;
}

function UsedAction(Action test_action) {
  return ((used_action == test_action) && (GSagsusedmode != eModeUseinv)) || 
         ((test_action == eGA_UseInv)  && (used_action == eGA_Use) && (GSagsusedmode == eModeUseinv)) || 
         ((test_action == eGA_GiveTo)  && (used_action == eGA_GiveTo) && (GSagsusedmode == eModeUseinv) && ItemGiven!=null);
}

function SetAction(Action new_action) {
  // set default action
  if (new_action == eMA_Default) new_action=default_action;
  // set corresponding cursormode
       if (new_action == eMA_WalkTo) mouse.Mode=eModeUsermode2;
  else if (new_action == eGA_LookAt) mouse.Mode=eModeLookat;
  else if (new_action == eGA_TalkTo) mouse.Mode=eModeTalkto;
  else if (new_action == eGA_GiveTo) mouse.Mode=eModeInteract;
  else if (new_action == eGA_PickUp) mouse.Mode=eModePickup;
  else if (new_action == eGA_Use)    mouse.Mode=eModeInteract;
  else if (new_action == eGA_Open)   mouse.Mode=eModeUsermode1;
  else if (new_action == eGA_Close)  mouse.Mode=eModeUsermode1;
  else if (new_action == eGA_Push)   mouse.Mode=eModeUsermode1;
  else if (new_action == eGA_Pull)   mouse.Mode=eModeUsermode1;
  // save action
  global_action=new_action;
}
function SetDefaultAction(Action def_action) {
  default_action=def_action;
  SetAction(eMA_Default);
}

// ============================= Load/Save game ===========================================

function GetLucasSavegameListBox(ListBox*lb) {
  // stores savegames in slots 100-199
  String buffer, sgdesc;
  int maxsavegames, counter=0;
  maxsavegames=99;
  lb.Clear();
  while (counter<maxsavegames) {
    buffer=String.Format("%d.", counter+1);
    sgdesc=Game.GetSaveSlotDescription(counter+100);
    if (sgdesc==null) sgdesc="";
    buffer=buffer.Append(sgdesc);
    lb.AddItem(buffer);
    counter++;
  }
  lb.TopItem=GStopsaveitem;
  lb.SelectedIndex=-1;
}

// ============================= GlobalCondition ===========================================
int GlobalCondition(eGlobCond condition) {
  // here are some conditions that are used many times in the script
  int cond;
  InventoryItem*ii=InventoryItem.GetAtScreenXY(mouse.x, mouse.y);
  GUIControl*gc=GUIControl.GetAtScreenXY(mouse.x, mouse.y);
  int gcid=-1;
  if (gc!=null) gcid=gc.ID;
  
  // if the mouse is in the inventory and mode Walk is selected
  if (condition == eGlob_MouseInvWalk ) 
    cond = (ii != null && (isAction(eMA_WalkTo)));

  // if the mouse is in the inventory and mode Pickup is selected
  else if (condition == eGlob_MouseInvPickup) 
    cond = (ii != null && (isAction(eGA_PickUp)));
    
  // if the mode is useinv and the mouse is over the active inv (like "use knife on knife")
  else if (condition == eGlob_InvOnInv) 
    cond =(player.ActiveInventory == ii && Mouse.Mode == eModeUseinv);
    
  // if the mode is talk or "Give", and the mouse isnt over a character
  else if (condition == eGlob_GiveTalkNoChar) {
    
    if (objHotTalk && isAction(eGA_TalkTo) ) {
      cond = false;     
    }  
    else {
      cond =((isAction(eGA_TalkTo) || (isAction(eGA_GiveTo) && (Mouse.Mode == eModeUseinv))) && (GetLocationType(mouse.x, mouse.y) != eLocationCharacter));
    }
  }
    
  // if its GIVE and the mouse isnt over a inv.item
  else if (condition == eGlob_GiveNoInv) 
    cond = ((Mouse.Mode == eModeInteract) && isAction(eGA_GiveTo) && (ii == null));
  
  // if the mouse is in the inventory and mode TalkTo is selected 
  else if (condition == eGlob_InvTalk)
    cond =  (ii != null && (isAction(eGA_TalkTo)));
  
  return cond;
}
// ============================= Verb Extensions and actions ===========================================

char ExtensionEx(int index, String name){
  //returns the extension in the position 'index' of the string 'name'.
  //returns 0 if the name has no extension or if you passed an empty string.
  if (name.Length==0) return 0;//if you passed an empty string
  int pos;
  pos=name.IndexOf(">");
  if (pos==-1) return 0;
  else if (pos+index<name.Length) return name.Chars[pos+index];
  else return 0;
}

char Extension(){
  // Check the (first) extension (>*) of a string
  return ExtensionEx(1,location);
}

function RemoveExtension(){
  //removes the extension of a string  
  int pos = location.IndexOf(">");
  int length=location.Length;
  if (Extension()!=0)location=location.Truncate(pos);
  return pos;
}

function AddExtension(char extension) {
  //adds an extension to a thing that doesn't have one
  int length=location.Length;
  if (Extension()==0) {
    location=location.Append(">n");
    location=location.ReplaceCharAt(length+1, extension);
  }
}

function SetAlternativeAction(char extension, Action alt_action) {
  if (alt_action==eMA_Default) {
    if (Extension()==extension)
      alternative_action = alt_action;
  }
  else {
    int button=action_button[alt_action];
    int normalbuttonpic=action_button_normal[alt_action];
    int overbuttonpic=action_button_highlight[alt_action];
    // used for setting the default action given the extension.
    GUIControl*gc=gMaingui.Controls[button];
    Button*b=gc.AsButton;
    if (Extension()==extension) {
      b.NormalGraphic=overbuttonpic;
      alternative_action=alt_action;
    }
    else b.NormalGraphic=normalbuttonpic;
    b.MouseOverGraphic=overbuttonpic;
  }
}

// Door extension for Open/Close
function OpenCloseExtension(int door_id) {
  if ((get_door_state(door_id)==0) || (get_door_state(door_id)==2)) AddExtension('o');
  else AddExtension('c');
}

function VariableExtensions() {
  // define here, which things will use a variable extension (>v)
  // by default, it's only used for doors.
  int r=player.Room;
  Object*oo=Object.GetAtScreenXY(mouse.x, mouse.y);
  int o=0;
  if (oo!=null) o=oo.ID;
  Hotspot*hh=Hotspot.GetAtScreenXY(mouse.x, mouse.y);
  int h=hh.ID;
  
  // Open/Close Extension:
  // Room | Hotspot |(Door_id)
       if (r==1 && h == 1)  OpenCloseExtension (20);
  //else if (r==2  && h == 2)  OpenCloseExtension (3);
  
  // Other possible extensions could be: Turn On/Turn Off
}

function CheckDefaultAction() {
  // you could want to change which extension activates which default action, or which button sprite
  // it changes. The extensions are characters, so remember to put them with single ', not ".
  int x=mouse.x;
  int y=mouse.y;
  location=Game.GetLocationName(x, y);
  
  // Setting default modes if the thing has no extension:
  if (Extension() == 0 ) {
    if (GetLocationType(x, y) == eLocationCharacter) // if it is a character
      AddExtension('t'); // set default action "talk to"
    else if ((GetLocationType(x, y)!=eLocationNothing) || (InventoryItem.GetAtScreenXY(x, y)!=null))
      // if its an inv item, a hotspot or an object
      AddExtension('l'); // set default action "look at"
    else
      AddExtension('n'); // set default action "none"
  }
  else if (Extension()=='v') { // if the default action depends on some events
    RemoveExtension();
    VariableExtensions();
  }
  if (GlobalCondition(eGlob_InvOnInv) || GlobalCondition(eGlob_GiveTalkNoChar) || GlobalCondition(eGlob_GiveNoInv) )
    //Dont send the name of the hotspt/obj/char/inv to the action bar and set default action "none"
    if (!GlobalCondition(eGlob_InvTalk)) location=">n";

  GSinvloc=location;
  
  // Set "Look" as default action for Inv items
  if ((Extension()=='u') && (InventoryItem.GetAtScreenXY(x, y) != null)) {
    // it's an inv item
    RemoveExtension();
    AddExtension('l'); // set default action "look at"
  }
  
  SetAlternativeAction('n', eMA_Default);
  SetAlternativeAction('g', eGA_GiveTo);
  SetAlternativeAction('p', eGA_PickUp);
  SetAlternativeAction('u', eGA_Use);
  SetAlternativeAction('o', eGA_Open);
  SetAlternativeAction('l', eGA_LookAt);
  SetAlternativeAction('s', eGA_Push);
  SetAlternativeAction('c', eGA_Close);
  SetAlternativeAction('t', eGA_TalkTo);
  SetAlternativeAction('y', eGA_Pull);  
  RemoveExtension();
  SHOWNlocation=location;
}
// ============================= ActionBar ===========================================

function UpdateActionBar (){
  // set the text in the action bar
  int action = global_action;

  act_object=SHOWNlocation;
  item="";
  if (Mouse.Mode==eModeUseinv) { // use or give inventory item
    item=player.ActiveInventory.Name;
    location=item;
    RemoveExtension();
    item=location;
  }
  else if (GlobalCondition (eGlob_MouseInvWalk)) { // if the mouse is in the inventory and modes Walk or pickup are selected
    if (oldschool_inv_clicks) action=eGA_LookAt;
    else {
      action=eGA_Use;
    }
  }
  
  TranslateAction(action, lang);
  madetext=tresult;
  // show action text
  ActionLine.Text=madetext;
  ActionLine.TextColor=ActionLabelColorNormal;
}


// ============================= translation ===========================================

String clearToSpace(String text) {
  int p=0;
  // ignore white spaces at the beginning
  while (p<text.Length && text.Chars[p]==' ') {
    p++;
  }
  // write white spaces until next white space
  while (p<text.Length && text.Chars[p]!=' ') {
    text=text.ReplaceCharAt(p, ' ');
    p++;
  }
  return text;
}

int getInteger() {
  int r=numbers.AsInt;
  numbers=clearToSpace(numbers);
  return r;
}

function SetActionButtons(Action action, String button_definition) {
  // extract data from button_definition
  String bd;
  
  if (IsTranslationAvailable ())
    bd=GetTranslation(button_definition);
  else {
    bd=button_definition;
  }
  
  bd=clearToSpace(bd);
  numbers=bd;
  action_button[action]=getInteger();
  action_button_normal[action]=getInteger();
  action_button_highlight[action]=getInteger();
  bd=numbers;
  int p=bd.Length-1;
  while (p>0) {
    action_l_keycode[action]=bd.Chars[p];
    p--;
    action_u_keycode[action]=bd.Chars[p];
    if (action_l_keycode[action]!=' ') p=0;
  }
  button_action[action_button[action]]=action;

}

function AdjustLanguage() {
  
  // English
  if (lang == eLangEN){
    // yes/no-keys
    key_u_yes= 'Y';
    key_l_yes= 'y';
    key_u_no= 'N';
    key_l_no= 'n';
    
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0  125  138 Qq");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 1  126  139 Ww");
    SetActionButtons(eGA_Use,    "a_button_use     2  127  140 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3  129  142 Aa");
    SetActionButtons(eGA_LookAt, "a_button_look_at 4  134  147 Ss");
    SetActionButtons(eGA_Push,   "a_button_push    5  131  144 Dd");
    SetActionButtons(eGA_Close,  "a_button_close   6  133  146 Zz");
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 7  130  143 Xx");
    SetActionButtons(eGA_Pull,   "a_button_pull    8  135  148 Cc");  
  }
  // German
  else if (lang == eLangDE) {
    // yes/no-keys
    key_u_yes= 'J';
    key_l_yes= 'j';
    key_u_no= 'N';
    key_l_no= 'n';    
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0 157 166 Qq");
    SetActionButtons(eGA_Use,    "a_button_use     1 158 167 Ww");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 2 159 168 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3 160 169 Aa");
    SetActionButtons(eGA_Close,  "a_button_close   4 161 170 Ss");  
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 5 162 171 Dd");
    SetActionButtons(eGA_LookAt, "a_button_look_at 6 163 172 Yy");
    SetActionButtons(eGA_Push,   "a_button_push    7 164 173 Xx");
    SetActionButtons(eGA_Pull,   "a_button_pull    8 165 174 Cc");
  }
  // Spanish
  else if (lang == eLangES) {
    // yes/no-keys
    key_u_yes= 'S';
    key_l_yes= 's';
    key_u_no= 'N';
    key_l_no= 'n';     
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0  6    11  Qq");
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 1  18   17  Ww");
    SetActionButtons(eGA_Use,    "a_button_use     2  4    145 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3  5    2   Aa");
    SetActionButtons(eGA_Close,  "a_button_close   4  8    7   Ss");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 5  10   9   Dd");
    SetActionButtons(eGA_LookAt, "a_button_look_at 6  122  75  Zz");
    SetActionButtons(eGA_Push,   "a_button_push    7  14   13  Xx");
    SetActionButtons(eGA_Pull,   "a_button_pull    8  16   15  Cc");  
  }  
  // French
  else if (lang == eLangFR) {
    // yes/no-keys
    key_u_yes= 'O';
    key_l_yes= 'o';
    key_u_no= 'N';
    key_l_no= 'n';     
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0  149  184 Qq");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 1  176  185 Ww");
    SetActionButtons(eGA_Use,    "a_button_use     2  177  186 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3  178  187 Aa");
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 4  179  188 Xx");
    SetActionButtons(eGA_Push,   "a_button_push    5  180  189 Dd");
    SetActionButtons(eGA_Close,  "a_button_close   6  181  190 Zz");
    SetActionButtons(eGA_LookAt, "a_button_look_at 7  182  191 Ss");
    SetActionButtons(eGA_Pull,   "a_button_pull    8  183  175 Cc");  
  }    
  // Italian
  else if (lang == eLangIT) {
    // yes/no-keys
    key_u_yes= 'S';
    key_l_yes= 's';
    key_u_no= 'N';
    key_l_no= 'n';     
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0  193  200 Qq");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 1  195  203 Ww");
    SetActionButtons(eGA_Use,    "a_button_use     2  196  204 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3  197  205 Aa");
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 4  198  206 Xx");
    SetActionButtons(eGA_Push,   "a_button_push    5  199  207 Dd");
    SetActionButtons(eGA_Close,  "a_button_close   6  201  213 Zz");
    SetActionButtons(eGA_LookAt, "a_button_look_at 7  202  214 Ss");
    SetActionButtons(eGA_Pull,   "a_button_pull    8  194  215 Cc");  
  }
  else if (lang == eLangPT) {
    // yes/no-keys
    key_u_yes= 'S';
    key_l_yes= 's';
    key_u_no= 'N';
    key_l_no= 'n';     
    // (eNum Name, Name, GUI Button ID, Sprite-Normal, Sprite-Highlight, Keyboard-Shortcut)
    SetActionButtons(eGA_GiveTo, "a_button_give    0  12   224 Qq");
    SetActionButtons(eGA_PickUp, "a_button_pick_up 1  216  225 Ww");
    SetActionButtons(eGA_Use,    "a_button_use     2  217  226 Ee");
    SetActionButtons(eGA_Open,   "a_button_open    3  218  227 Aa");
    SetActionButtons(eGA_TalkTo, "a_button_talk_to 4  219  228 Xx");
    SetActionButtons(eGA_Push,   "a_button_push    5  223  232 Dd");
    SetActionButtons(eGA_Close,  "a_button_close   6  221  230 Zz");
    SetActionButtons(eGA_LookAt, "a_button_look_at 7  222  231 Ss");
    SetActionButtons(eGA_Pull,   "a_button_pull    8  220  229 Cc");  
  }   
  
  // --- load font corresponding to language and screen width ---
  String font_info;
  if (System.ScreenWidth<640)
    font_info=GetTranslation("font_lowres: 1  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  1  1");
  else 
    font_info=GetTranslation("font_hires: 1  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  1  1");
    //Game.NormalFont
  font_info=clearToSpace(font_info);
  numbers=font_info;
  
  // Setting the fonts from the string: font_info
  Game.SpeechFont       = getInteger(); // Speech
  ActionLine.Font       = getInteger(); // Status-Line
  Game.NormalFont       = getInteger(); // Dialog GUI
  OptionsTitle.Font     = getInteger(); // Options-GUI Title
  OptionsSave.Font      = getInteger(); // Options-GUI Save Button
  OptionsLoad.Font      = getInteger(); // Options-GUI Load Button
  OptionsQuit.Font      = getInteger(); // Options-GUI Quit Button
  OptionsPlay.Font      = getInteger(); // Options-GUI Play Button
  gPausedText.Font      = getInteger(); // Game Paused Message
  OptionsDefault.Font   = getInteger(); // Options-GUI Default Button
  OptionsMusic.Font     = getInteger(); // Options-GUI Music Label
  OptionsSpeed.Font     = getInteger(); // Options-GUI Gamespeed Label
  OptionsRestart.Font   = getInteger(); // Options-GUI Restart Button
  RestoreTitle.Font     = getInteger(); // Restore-GUI Title
  RestoreCancel.Font    = getInteger(); // Restore-GUI Cancel Button
  SaveTitle.Font        = getInteger(); // Save-GUI Title
  SaveOK.Font           = getInteger(); // Save-GUI Okay Button
  SaveCancel.Font       = getInteger(); // Save-GUI Cancel Button
  gConfirmexitText.Font = getInteger(); // Confirm Exit Message
  gRestartText.Font     = getInteger(); // Restart Game Message
}

function AdjustGUIText() {

  // English
  if (lang == eLangEN){
    // english is the default language, nothing to adjust
    return;
  }
  else if (lang == eLangDE) {
    // German
    OptionsTitle.Text   = "Optionen";
    OptionsMusic.Text   = "Musik Lautst�rke";
    OptionsSound.Text   = "Sound Effekte";
    OptionsSpeed.Text   = "Geschwindigkeit";
    OptionsDefault.Text = "Standard";
    OptionsSave.Text    = "Speichern";
    OptionsLoad.Text    = "Laden";
    OptionsRestart.Text = "Neustart";
    OptionsQuit.Text    = "Beenden";
    OptionsPlay.Text    = "Weiter";
    gPausedText.Text    = "Pause. Leertaste f�r weiter";
    RestoreTitle.Text   = "W�hlen Sie ein Spiel zum Laden";
    RestoreCancel.Text  = "Abbruch";
    SaveTitle.Text      = "Name f�r das Spiel";
    SaveOK.Text         = "Speichern";
    SaveCancel.Text     = "Abbruch";
    gConfirmexitText.Text = "M�chten Sie das Spiel beenden? (J/N)";
    gRestartText.Text   = "M�chten Sie das Spiel neu starten? (J/N)";
  }
  else if (lang == eLangES) {
    // Spanish
    OptionsTitle.Text   = "Opciones";
    OptionsMusic.Text   = "Volumen de la m�sica";
    OptionsSound.Text   = "Efectos de sonido ";
    OptionsSpeed.Text   = "Velocidad de juego";
    OptionsDefault.Text = "Restablecer";
    OptionsSave.Text    = "Guardar";
    OptionsLoad.Text    = "Cargar";
    OptionsRestart.Text = "Reiniciar";
    OptionsQuit.Text    = "Salir";
    OptionsPlay.Text    = "Volver";
    gPausedText.Text    = "Juego en pausa. Pulsa Espacio para continuar";
    RestoreTitle.Text   = "Por favor, elige el juego a cargar";
    RestoreCancel.Text  = "Cancelar";
    SaveTitle.Text      = "Por favor, introduce un nombre";
    SaveOK.Text         = "Guardar";
    SaveCancel.Text     = "Cancelar";
    gConfirmexitText.Text = "�Seguro que quieres salir? (S/N)";
    gRestartText.Text   = "�Seguro que quieres reiniciar? (S/N)";  
  }
  else if (lang == eLangFR) {
    // French
    OptionsTitle.Text   = "Param�tres";
    OptionsMusic.Text   = "Volume de la musique";
    OptionsSound.Text   = "Volume des sons";
    OptionsSpeed.Text   = "Vitesse du jeu";
    OptionsDefault.Text = "R�initialiser";
    OptionsSave.Text    = "Sauver";
    OptionsLoad.Text    = "Charger";
    OptionsRestart.Text = "Red�marrer";
    OptionsQuit.Text    = "Quitter";
    OptionsPlay.Text    = "Reprendre";
    gPausedText.Text    = "PAUSE. Appuyez sur la barre d'espacement pour reprendre";
    RestoreTitle.Text   = "Choisissez une partie � charger";
    RestoreCancel.Text  = "Annuler";
    SaveTitle.Text      = "Saisissez un nom";
    SaveOK.Text         = "Sauver";
    SaveCancel.Text     = "Annuler";
    gConfirmexitText.Text = "Voulez-vous vraiment quitter? (O/N)";
    gRestartText.Text   = "Voulez-vous vraiment red�marrer? (O/N)";
  }  
  else if (lang == eLangIT) {
    // Italian
   OptionsTitle.Text   = "Opzioni";
   OptionsMusic.Text   = "Volume della Musica";
   OptionsSound.Text   = "Effetti Sonori";
   OptionsSpeed.Text   = "Velocita' del Gioco";
   OptionsDefault.Text = "Default";
   OptionsSave.Text    = "Salva";
   OptionsLoad.Text    = "Carica";
   OptionsRestart.Text = "Ricomincia";
   OptionsQuit.Text    = "Esci";
   OptionsPlay.Text    = "Continua";
   gPausedText.Text    = "Partita in Pausa. Premi Spazio per Continuare";
   RestoreTitle.Text   = "Scegli una partita da caricare";
   RestoreCancel.Text  = "Cancella";
   SaveTitle.Text      = "Inserisci un nome";
   SaveOK.Text         = "Salva";
   SaveCancel.Text     = "Cancella";
   gConfirmexitText.Text = "Sei sicuro/a che vuoi uscire? (S/N)";
   gRestartText.Text   = "Sei sicuro/a che vuoi ricominciare? (S/N)";
  }
  else if (lang == eLangPT) {
    // Italian
   OptionsTitle.Text   = "Op��es";
   OptionsMusic.Text   = "Volume M�sica";
   OptionsSound.Text   = "Efeitos Sonoros";
   OptionsSpeed.Text   = "Velocidade";
   OptionsDefault.Text = "Standard";
   OptionsSave.Text    = "Gravar";
   OptionsLoad.Text    = "Restaurar";
   OptionsRestart.Text = "Recome�ar";
   OptionsQuit.Text    = "Desistir";
   OptionsPlay.Text    = "Continuar";
   gPausedText.Text    = "Pausa. Prima Space para continuar";
   RestoreTitle.Text   = "Por favor escolha um jogo para restaurar";
   RestoreCancel.Text  = "Cancelar";
   SaveTitle.Text      = "Por favor insira um nome";
   SaveOK.Text         = "Gravar";
   SaveCancel.Text     = "Cancelar";
   gConfirmexitText.Text = "De certeza que quer desistir ? (S/N)";
   gRestartText.Text   = "De certeza que quer recome�ar? (S/N)";
  }  
}

function InitGuiLanguage() {
  AdjustLanguage();
  int i;
  GUIControl*gc;
  Button*b;
  
  while (i < A_COUNT_) {
    gc = gMaingui.Controls[action_button[i]];
    b =  gc.AsButton;
    b.NormalGraphic=action_button_normal[i];
    i++;
  }
}
// ============================= Player function ===========================================

function freeze_player(){player_frozen = true;}

function unfreeze_player(){player_frozen = false;}

#ifnver 3.4
function FaceDirection(this Character*, CharacterDirection dir) {
  int dx;
  if (dir==eDirectionLeft) dx=-1;
  if (dir==eDirectionRight) dx=1;
  
  int dy;
  if (dir==eDirectionUp) dy=-1;
  else if (dir==eDirectionDown) dy=1;
  
  this.FaceLocation(this.x+dx, this.y+dy);
}
#endif

function SetPlayer(Character*ch) {
  //use this instead of SetPlayerCharacter function.
  if (player.Room==ch.Room) { // if old and new player character are in the same room then scroll room
    int x=GetViewportX();
    int tx=ch.x-160;
    if (tx<0) tx = 0;
    else if (tx>Room.Width-320) tx=Room.Width-320;
    SetViewport(x, GetViewportY());
    while (x<tx) {
      x+=X_SPEED;
      if (x>tx) x=tx;
      SetViewport(x, GetViewportY());
      Wait(1);
    }
    while (x>tx) {
      x -= X_SPEED;
      if (x<tx) x=tx;
      SetViewport(x, GetViewportY());
      Wait (1);
    }
  }
  else // if they are in different rooms
    player.StopMoving();
    player.Clickable=true;
    ch.Clickable=false;
    ch.SetAsPlayer();
    ReleaseViewport();
}

int MovePlayerEx(int x, int y, WalkWhere direct) {
  // Move the player character to x,y coords, waiting until he/she gets there,
  // but allowing to cancel the action by pressing a mouse button.
  if (player_frozen==false) {
    mouse.ChangeModeGraphic(eModeWait, cursorspritenumber);
    GScancelable = 0;
    player.Walk(x, y, eNoBlock, direct);
    // wait for release of mouse button
    while (player.Moving && (mouse.IsButtonDown(eMouseLeft) || mouse.IsButtonDown(eMouseRight))) {
      Wait(1);
      mouse.Update();
      CheckDefaultAction();
    }
    // abort moving on new mouse down
    while (player.Moving) {
      int xm=mouse.x;
      int ym=mouse.y;
      InventoryItem*ii=InventoryItem.GetAtScreenXY(xm, ym);
      if (mouse.IsButtonDown(eMouseLeft) && (GUI.GetAtScreenXY(xm, ym)==null || ii!=null)) {
        player.StopMoving();
        GScancelable = 1;
      }
      else if (mouse.IsButtonDown(eMouseRight) && (GUI.GetAtScreenXY(xm, ym)==null || ii!=null)) {
        player.StopMoving();
        GScancelable = 2;
      }
      else {
        Wait(1);
        mouse.Update();
        CheckDefaultAction ();
      }
    }
    mouse.ChangeModeGraphic(eModeWait, blankcursorspritenumber);
    //if (GScancelable==0) return 1;
    //BUG FIX: AdventureTreff: 
    if (GScancelable==0 && player.x==x && player.y==y) return 2;
    else if (GScancelable == 0) return 1;
    else return 0;
  }
  else return 0;
}

int MovePlayer(int x, int y) {
  //Move the player character to x,y coords, waiting until he/she gets there, but allowing to cancel the action
  //by pressing a mouse button.
  return MovePlayerEx (x, y, eWalkableAreas);
}

// ============================= Go ===========================================
int GoToCharacterEx(Character*chwhogoes, Character*ch, CharacterDirection dir, int xoffset, int yoffset, bool NPCfacesplayer, int blocking) {
  //Goes to a character staying at the side defined by 'direction': 1 up, 2 right, 3 down, 4 left
  //and it stays at xoffset or yofsset from the character. NPCfacesplayer self-explained. ;)
  // blocking: 0=non-blocking; 1=blocking; 2=semi-blocking
  Character*pl = chwhogoes;
  int chx, chy;
  chx=ch.x;
  chy=ch.y;
  int arrived=1;
  if (Offset(pl.x, chx) > xoffset || Offset(pl.y, chy) > yoffset) {
    if (dir == 0) {
      // get the nearest position
      if (Offset (chx, pl.x) >= Offset(chy, pl.y)) {
        // right or left
        if (pl.x >= chx) dir = eDirectionRight;
        else dir = eDirectionLeft;
      }
      else {
        if (pl.y >= chy) dir = eDirectionDown; 
        else dir = eDirectionUp;
      }
    }
    // calculate target position
    if (dir == eDirectionUp)    chy-=yoffset;
    else if (dir == eDirectionRight) chx+=xoffset;
    else if (dir == eDirectionDown)  chy+=yoffset;
    else if (dir == eDirectionLeft)  chx-=xoffset;
    // move character
    if (blocking==0) {
      pl.Walk(chx, chy);
      arrived = 0;
    }
    else if (blocking==1) {
      pl.Walk(chx, chy, eBlock, eWalkableAreas);
      arrived=1;
    }
    else if (blocking==2) arrived=MovePlayer(chx, chy);
  }
  if (arrived>0) {
    // characters only face each other after the moving character arrived at the target point
    if (NPCfacesplayer) ch.FaceCharacter(pl, eBlock);
    pl.FaceCharacter(ch, eBlock);
  }
  return arrived;
}

int NPCGoToCharacter(Character*chwhogoes, Character*chtogoto, CharacterDirection dir, bool NPCfacesplayer, int blocking) {
  // same as above but with default x and y offset.
  int defaultxoffset=35;
  int defaultyoffset=20;
  return GoToCharacterEx (chwhogoes, chtogoto, dir, defaultxoffset, defaultyoffset, NPCfacesplayer, blocking);
}

int GoToCharacter(Character*ch, CharacterDirection dir, bool NPCfacesplayer, int blocking) {
  // same as above but with default x and y offset.
  int defaultxoffset=35;
  int defaultyoffset=20;
  return GoToCharacterEx (player, ch, dir, defaultxoffset, defaultyoffset, NPCfacesplayer, blocking);
}

function GoTo(int blocking) {
  // Goes to whatever the player clicked on.
  // blocking: 0=non-blocking; 1=blocking; 2=semi-blocking
  int xtogo, ytogo;
  int locationtype=GetLocationType(mouse.x, mouse.y);
  Hotspot*hot_spot=Hotspot.GetAtScreenXY(mouse.x, mouse.y);
  int arrived=0;
  
  if (locationtype==eLocationCharacter)
    arrived=GoToCharacter(Character.GetAtScreenXY(mouse.x, mouse.y), 0, false, blocking);
  else {
    if (locationtype==eLocationHotspot && hot_spot.ID>0) {
      xtogo=hot_spot.WalkToX;
      ytogo=hot_spot.WalkToY;
    }
    if (locationtype==eLocationObject) {
      Object*obj=Object.GetAtScreenXY(mouse.x, mouse.y);
      xtogo=obj.X;
      ytogo=obj.Y;
    }
    if (hot_spot==hotspot[0]) {
      xtogo=mouse.x;
      ytogo=mouse.y;
    }
    else {
      xtogo=mouse.x;
      ytogo=mouse.y;
    }
    xtogo+=GetViewportX ();
    ytogo+=GetViewportY ();
    if (blocking==0) player.Walk(xtogo, ytogo);
    else if (blocking==1) {
      player.Walk(xtogo, ytogo, eBlock);
      arrived=1;
    }
    else if (blocking==2) arrived=MovePlayer(xtogo, ytogo);
  }
  return arrived;
}

function Go() {
  // Go to whatever the player clicked on. You can cancel the action, and returns 1 if the player has gone to it.
  return GoTo(2);
}

function set_approaching_char(bool enable){
  // If set to true, the player walks to other chars before talking or giving items.
  approachCharInteract = enable;
}

function WalkOffScreen(){
 //handles the action of hotspots with exit extension ('>e').
 //double click in such hotspots/objects... will make the player skip
 //walking to it. Look the documentation for more information on exits.
  
  // doubleclick
  if (UsedAction(eMA_WalkTo)) {
    if (timer_run == true) 
    {
      timer_run=false;
      if (MovePlayerEx(player.x,player.y,eWalkableAreas)>0) {
        if (GSloctype==eLocationHotspot) hotspot[GSlocid].RunInteraction(eModeUsermode1);
        else if (GSloctype==eLocationObject) object[GSlocid].RunInteraction(eModeUsermode1);
      }
    }
    else
    {
      //doubleclick = false;
      if (!disableDoubleclick) timer_run = true;
      if (Go()){
        int x=player.x,y=player.y;
        int offset=walkoffscreen_offset;
        int dir=ExtensionEx(2,GSlocname);
        if      (dir=='u') y-=offset;
        else if (dir=='d') y+=offset;
        else if (dir=='l') x-=offset;
        else if (dir=='r') x+=offset;
        if (MovePlayerEx(x,y,eAnywhere)>0){
          if (GSloctype==eLocationHotspot) hotspot[GSlocid].RunInteraction(eModeUsermode1);
          else if (GSloctype==eLocationObject) object[GSlocid].RunInteraction(eModeUsermode1);
        }
      }    
    } 
  }
}

// ============================= Unhandled Events ===========================================

  // Please check this section and replace the boring default values with your own.
  // If you courious, how it all works, keep on reading this comment  ;-)
  //
  //Check modes with: if(UsedAction(A_???)), check types by if(type==#). types:
  // 1   a hotspot
  // 2   a character
  // 3   an object
  // 4   an inventory item.
  // 5   inv. item on hotspot
  // 6   inv. item on character
  // 7   inv. item on object
  // 8   inv. item on inv. item
  //
  // You have the string "locationname" that is the name of
  // what you clicked on, and the string "usedinvname" that is
  // the name of the item that was used on where you clicked (only for types 5,6,7,8)
    
function Unhandled(int door_script) {
  InventoryItem*ii=InventoryItem.GetAtScreenXY(mouse.x, mouse.y);
  int type=0;
  if (GSloctype==eLocationHotspot) type=1;
  if (GSloctype==eLocationCharacter) type=2;
  if (GSloctype==eLocationObject) type=3;
  String locationname=GSlocname;
  String usedinvname;
  String translation;
  translation=Game.TranslationFilename;
  location=locationname;
  RemoveExtension();
  locationname=location;
  if (ii!=null) type = 4;
  if (GSagsusedmode == eModeUseinv) {
    if (ii!=null) {
      usedinvname=ii.Name;
      location=usedinvname;
      RemoveExtension();
      usedinvname=location;
      if (type>0) type+=4;
    }
  }
  if (GSagsusedmode!=eModeUsermode2 && type!=0) {
    if (type==2 || type==6) player.FaceCharacter(character[GSlocid], eBlock);

    // unhandled USE
    if (UsedAction(eGA_Use)) {
      // use inv on inv
      if (type >= 5) player.Say("That won't do any good.");
      // use
      else player.Say("I can't use that.");
    }
    
    // unhandled LOOK AT  
    else if (UsedAction(eGA_LookAt)) {
      // look at hotspots, objects etc.
      if (type!=2) player.Say ("Nice %s", locationname);
      // look at characters
      else player.Say("It's %s",locationname); 
    }
    
    // unhandled PUSH
    else if (UsedAction(eGA_Push)) {
      // push everything except characters
      if (type!=2) player.Say("I can't push that.");
      // push characters
      else player.Say("I can't push %s",locationname);
    }
    
    // unhandled PULL
    else if (UsedAction(eGA_Pull)){
      // pull everything except characters
      if (type!=2) player.Say("I can't pull that.");
      // pull characters
      else player.Say("I can't pull %s",locationname);
    }
    
    // unhandled CLOSE
    else if (UsedAction(eGA_Close)){
      if (door_script == 1) player.Say("It has already been closed.");
      else if (type == 2) player.Say("Doing that with %s is not a good idea.",locationname);
      else player.Say("I can't close that.");
    }
    
    // unhandled OPEN
    else if (UsedAction(eGA_Open)) {
      if (door_script == 1) player.Say("It is already open.");
      else if (type ==2) player.Say("%s would not like it.",locationname);
      else player.Say("I can't open that.");
    }
    
    // unhandled PICKUP
    else if (UsedAction(eGA_PickUp)) {
      if (type!=2) player.Say("I don't need that.");
      else player.Say("I don't want to pick %s up.",locationname);
    }

    // unhandled TALK TO
    else if (UsedAction(eGA_TalkTo)) {
      if (type==2) player.Say("I don't want to talk to %s", locationname);
      else player.Say("I have nothing to say.");
    }
    
    // unhandled USE INV
    else if (UsedAction(eGA_UseInv)) player.Say("That won't do any good.");
    
    // unhandled GIVE
    else if (ItemGiven != null) player.Say("I'd rather keep it.");   
    
    // unhandled DEFAULT
    else if (type==4) player.Say("I can't do that.");

  }
}

// ============================= interaction functions ===========================================
function EnterRoom(this Character*, int newRoom, int x, int y, CharacterDirection dir) {
  this.ChangeRoom(newRoom, x, y);
  this.FaceDirection(dir);
}

function any_click_move (int x, int y, CharacterDirection dir) {
  int result=MovePlayer(x, y);
  if (result) {
    player.FaceDirection(dir);
    Wait(5);
  }
  return result;
}

function any_click_walk(int x, int y, CharacterDirection dir){
  int result=1;
  if (UsedAction(eMA_WalkTo)) any_click_move(x, y, dir);
  else result=0;
  return result;
  // 0 = unhandled
  // 1 = handled
}

function any_click_walk_look(int x, int y, CharacterDirection dir, String lookat){
  int result=any_click_walk(x, y, dir);
  //if (result==0 && UsedAction(eGA_LookAt) && lookat.Length>0) {
  if (result==0 && lookat.Length>0) {
    result=1;
    if (any_click_move(x, y, dir)) {
      player.Say(lookat);
    }
  }
  return result;
  // 0 = unhandled
  // 1 = handled
}

function any_click_use_inv(InventoryItem*iitem, int x, int y, CharacterDirection dir) {
  int result=0;
  if (UsedAction(eGA_UseInv)) {
    if (player.ActiveInventory == iitem) {
      if (any_click_move (x, y, dir)) result = 2;
      else                            result = 1;
    }
  }
  return result;
  // 0 = unhandled
  // 1 = handled, but canceled
  // 2 = use this item
}

#ifdef USE_OBJECT_ORIENTED_AUDIO
function any_click_walk_look_pick(int x, int y, CharacterDirection dir, String lookat, int obj, InventoryItem*iitem, AudioClip *sound) {
  AudioChannel *chan;
  int result=MovePlayer(x, y);
  if (result>0 && UsedAction(eGA_PickUp)) {
    if (any_click_move (x, y, dir)) {
      if (lookat.Length>0) player.Say(lookat);
      if (sound != null)chan = sound.Play();
      if (obj>=0) object[obj].Visible=false;
      if (iitem!=null) player.AddInventory(iitem);
      result=2;
    }
  }
  return result;
  // 0 = unhandled
  // 1 = handled, but canceled
  // 2 = picked up
}
#endif

#ifndef USE_OBJECT_ORIENTED_AUDIO
function any_click_walk_look_pick(int x, int y, CharacterDirection dir, String lookat, int obj, InventoryItem*iitem, int sound) {
  int result=MovePlayer(x, y);
  if (result>0 && UsedAction(eGA_PickUp)) {
    if (any_click_move (x, y, dir)) {
      if (lookat.Length>0) player.Say(lookat);
      if (sound != 0)PlaySound(sound);
      if (obj>=0) object[obj].Visible=false;
      if (iitem!=null) player.AddInventory(iitem);
      result=2;
    }
  }
  return result;
  // 0 = unhandled
  // 1 = handled, but canceled
  // 2 = picked up
}
#endif
// ============================= Door functions ==========================================

function set_door_strings(String lookat, String islocked, String wrongitem, String closefirst, String unlock, String relock) {
  if (!String.IsNullOrEmpty(lookat))     door_strings[0]=lookat;
  if (!String.IsNullOrEmpty(islocked))   door_strings[1]=islocked;
  if (!String.IsNullOrEmpty(wrongitem))  door_strings[2]=wrongitem;
  if (!String.IsNullOrEmpty(closefirst)) door_strings[3]=closefirst;
  if (!String.IsNullOrEmpty(unlock))     door_strings[4]=unlock;
  if (!String.IsNullOrEmpty(relock))     door_strings[5]=relock;

}

String get_door_strings(String what_type) {
  String ret_value;
  
       if (what_type == "lookat")     ret_value= door_strings[0];
  else if (what_type == "islocked")   ret_value= door_strings[1];
  else if (what_type == "wrongitem")  ret_value= door_strings[2];
  else if (what_type == "closefirst") ret_value= door_strings[3];
  else if (what_type == "unlock")     ret_value= door_strings[4];
  else if (what_type == "relock")     ret_value= door_strings[5];
  else ret_value= "INVALID STRING";
  
  if (String.IsNullOrEmpty(ret_value)) return "";
  else return ret_value;
}

#ifdef USE_OBJECT_ORIENTED_AUDIO
function any_click_on_door_special(int door_id, int obj, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir, AudioClip *opensound, AudioClip *closesound, int key, int closevalue) {
  // key = -1: masterkey - even locked doors will be opened
  // key = -2: door can't be unlocked (like rusted) 
  AudioChannel *chan;
  int result=1;
  
  if (UsedAction(eGA_Close)) {
    if (get_door_state(door_id)==0 || get_door_state(door_id)==2)
      Unhandled(1);
    else if (get_door_state(door_id)==1) {
      if (any_click_move (x, y, dir)) {
        if (closesound != null) chan = closesound.Play();
        // Play default sound
        else if (closeDoorSound != null) chan = closeDoorSound.Play();
        object[obj].Visible=false;
        set_door_state(door_id, closevalue);
      }
    }
  }
  else if (UsedAction(eGA_Open)) {
    if (get_door_state(door_id)==0 || (get_door_state(door_id)==2 && key==-1)) {
      if (any_click_move (x, y, dir))
      {
        if (opensound != null) chan = opensound.Play();
        // Play default sound
        else if (openDoorSound != null) chan = openDoorSound.Play();     
        
        object[obj].Visible=true;
        set_door_state(door_id, 1);
      }
    }
    else if (get_door_state(door_id)==1) Unhandled(1);
    else if (get_door_state(door_id)==2) {
      if (any_click_move (x, y, dir)) if (!String.IsNullOrEmpty(get_door_strings("islocked"))) player.Say(get_door_strings("islocked"));
    }
  }
  else if (UsedAction(eMA_WalkTo)) 
  {
    
    if (get_door_state(door_id)==1) {
      if (timer_run == true && openDoorDoubleclick==true) 
      {
        timer_run = false;
        if (MovePlayerEx(player.x,player.y,eWalkableAreas)>0) player.EnterRoom(nr_room, nr_x, nr_y, nr_dir);
        result = 2;
      }
      else 
      {
        //doubleclick = false;
        if (openDoorDoubleclick && !disableDoubleclick) timer_run = true;
        if (Go()){
          player.EnterRoom(nr_room, nr_x, nr_y, nr_dir);
          result=2;          
        }
        
      }
    }else any_click_move(x, y, dir);

  }
  else if (UsedAction (eGA_LookAt) && !String.IsNullOrEmpty(get_door_strings("lookat"))) {
    if (any_click_move (x, y, dir)) if (!String.IsNullOrEmpty(get_door_strings("lookat")))player.Say(get_door_strings("lookat"));
  }
  else if (UsedAction(eGA_UseInv) && key>=0) {
    if (any_click_move (x, y, dir)) {
      if (player.ActiveInventory==inventory[key]) {
        if (get_door_state(door_id)==1) { 
          if (!String.IsNullOrEmpty(get_door_strings("closefirst"))) player.Say(get_door_strings("closefirst"));
        }
        else if (get_door_state(door_id)==2) {
          if (unlockDoorSound != null) chan = unlockDoorSound.Play();
          if (!String.IsNullOrEmpty(get_door_strings("unlock"))) player.Say(get_door_strings("unlock"));
          set_door_state(door_id, closevalue);
        } 
        else if (get_door_state(door_id)==0) {
          object[obj].Visible=false;
          set_door_state(door_id, 2);
          if (!String.IsNullOrEmpty(get_door_strings("relock"))) player.Say(get_door_strings("relock"));
        }
      }
      else if (!String.IsNullOrEmpty(get_door_strings("wrongitem"))) player.Say(get_door_strings("wrongitem"));
    }
  }
  else result=0;
  
  return result;
  // 0 = unhandled
  // 1 = handled
  // 2 = NewRoom
}
#endif

#ifnver 3.2
function any_click_on_door_special(int door_id, int obj, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir, int opensound, int closesound, int key, int closevalue) {
  // key = -1: masterkey - even locked doors will be opened
  // key = -2: door can't be unlocked (like rusted) 
  int result=1;
  
  if (UsedAction(eGA_Close)) {
    if (get_door_state(door_id)==0 || get_door_state(door_id)==2)
      Unhandled(1);
    else if (get_door_state(door_id)==1) {
      if (any_click_move (x, y, dir)) {
        if (closesound != 0) PlaySound(closesound);
        // Play default sound
        else if (closeDoorSound != 0) PlaySound(closeDoorSound);
        object[obj].Visible=false;
        set_door_state(door_id, closevalue);
      }
    }
  }
  else if (UsedAction(eGA_Open)) {
    if (get_door_state(door_id)==0 || (get_door_state(door_id)==2 && key==-1)) {
      if (any_click_move (x, y, dir))
      {
        if (opensound != 0) PlaySound(opensound);
        // Play default sound
        else if (openDoorSound != 0) PlaySound(openDoorSound);     
        
        object[obj].Visible=true;
        set_door_state(door_id, 1);
      }
    }
    else if (get_door_state(door_id)==1) Unhandled(1);
    else if (get_door_state(door_id)==2) {
      if (any_click_move (x, y, dir)) if (!String.IsNullOrEmpty(get_door_strings("islocked"))) player.Say(get_door_strings("islocked"));
    }
  }
  else if (UsedAction(eMA_WalkTo)) 
  {
    
    if (get_door_state(door_id)==1) {
      if (timer_run == true && openDoorDoubleclick==true) 
      {
        timer_run = false;
        if (MovePlayerEx(player.x,player.y,eWalkableAreas)>0) player.EnterRoom(nr_room, nr_x, nr_y, nr_dir, true);
        result = 2;
      }
      else 
      {
        //doubleclick = false;
        if (openDoorDoubleclick && !disableDoubleclick)timer_run = true;
        if (Go()){
          player.EnterRoom(nr_room, nr_x, nr_y, nr_dir, true);
          result=2;          
        }
        
      }
    }else any_click_move(x, y, dir);

  }
  else if (UsedAction (eGA_LookAt) && !String.IsNullOrEmpty(get_door_strings("lookat"))) {
    if (any_click_move (x, y, dir)) if (!String.IsNullOrEmpty(get_door_strings("lookat")))player.Say(get_door_strings("lookat"));
  }
  else if (UsedAction(eGA_UseInv) && key>=0) {
    if (any_click_move (x, y, dir)) {
      if (player.ActiveInventory==inventory[key]) {
        if (get_door_state(door_id)==1) { 
          if (!String.IsNullOrEmpty(get_door_strings("closefirst"))) player.Say(get_door_strings("closefirst"));
        }
        else if (get_door_state(door_id)==2) {
          if (unlockDoorSound != 0) PlaySound(unlockDoorSound);
          if (!String.IsNullOrEmpty(get_door_strings("unlock"))) player.Say(get_door_strings("unlock"));
          set_door_state(door_id, closevalue);
        } 
        else if (get_door_state(door_id)==0) {
          object[obj].Visible=false;
          set_door_state(door_id, 2);
          if (!String.IsNullOrEmpty(get_door_strings("relock"))) player.Say(get_door_strings("relock"));
        }
      }
      else if (!String.IsNullOrEmpty(get_door_strings("wrongitem"))) player.Say(get_door_strings("wrongitem"));
    }
  }
  else result=0;
  
  return result;
  // 0 = unhandled
  // 1 = handled
  // 2 = NewRoom
}
#endif

function any_click_on_door(int door_id, int obj, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir) {
#ifdef USE_OBJECT_ORIENTED_AUDIO
return any_click_on_door_special (door_id, obj, x, y, dir, nr_room, nr_x, nr_y, nr_dir, null, null, 0, 0);
#endif

#ifndef USE_OBJECT_ORIENTED_AUDIO
return any_click_on_door_special (door_id, obj, x, y, dir, nr_room, nr_x, nr_y, nr_dir, 0, 0, 0, 0);
#endif
}

// ============================= AGS internal functions ==========================================

function on_mouse_click(MouseButton button) {
  
  if (!is_gui_disabled()) {
    int mrx=mouse.x+GetViewportX();
    int mry=mouse.y+GetViewportY();
    int x=mouse.x;
    int y=mouse.y;
    // get location under mouse cursor
    GSloctype=GetLocationType(x, y);
    GSlocname=Game.GetLocationName(x, y);
    GSagsusedmode=Mouse.Mode;
    used_action=global_action;
    
    InventoryItem*ii = InventoryItem.GetAtScreenXY(x, y);
    if (GSloctype==eLocationHotspot) {
      Hotspot*h=Hotspot.GetAtScreenXY(x, y);
      GSlocid=h.ID;
      
    }
    else if (GSloctype==eLocationCharacter) {
      Character*c=Character.GetAtScreenXY(x, y);
      GSlocid=c.ID;
    }
    else if (GSloctype==eLocationObject) {
      Object*o=Object.GetAtScreenXY(x, y);
      GSlocid=o.ID;
    }
    else if (ii!=null) GSlocid=ii.ID;
    
    
    
    
    if (IsGamePaused()) {
      // Game is paused, so do nothing (ie. don't allow mouse click)
    }
    // Mousebutton Left
    else if (button==eMouseLeft) 
    {
        
      if (GlobalCondition(eGlob_InvOnInv) || GlobalCondition(eGlob_GiveTalkNoChar) || GlobalCondition(eGlob_GiveNoInv)) {
        // Do nothing, if:
        // the mode is useinv and the mouse is over the active inv (like "use knife on knife")
        // or the mode is talk, or "Give", and the mouse isnt over a character
        // or its GIVE and the mouse isnt over a inv.item

      }
      else if (ExtensionEx(1, GSlocname)=='e') {
        UpdateActionBar();
        ActionLine.TextColor=ActionLabelColorHighlighted;
        WalkOffScreen();
      }
      // walk to
      else if (GSagsusedmode==eModeUsermode2) {
        ActionLine.TextColor=ActionLabelColorHighlighted;
        #ifnver 3.4
        if (IsInteractionAvailable(x, y, GSagsusedmode)) ProcessClick (x, y, GSagsusedmode);
        else ProcessClick(x, y, eModeWalkto);
        #endif
        #ifver 3.4
        if (IsInteractionAvailable(x, y, GSagsusedmode)) Room.ProcessClick (x, y, GSagsusedmode);
        else Room.ProcessClick(x, y, eModeWalkto);
        #endif
        
      }   
      // talkto
      else if (GSagsusedmode==eModeTalkto && IsInteractionAvailable(x, y, GSagsusedmode) && GSloctype==eLocationCharacter) {
        ActionLine.TextColor=ActionLabelColorHighlighted;
        if (approachCharInteract == false) character[GSlocid].RunInteraction(GSagsusedmode); 
        else {
          if (GoToCharacter(character[GSlocid], 0, NPC_facing_player, 2)) character[GSlocid].RunInteraction(GSagsusedmode);
        }
        SetAction(eMA_Default);
      }
      // Giveto
      else if ((GSagsusedmode == eModeUseinv) && GSloctype==eLocationCharacter && isAction(eGA_GiveTo)) {
        ActionLine.TextColor=ActionLabelColorHighlighted;
        ItemGiven=player.ActiveInventory;
        
        if (approachCharInteract == false) {
          if (IsInteractionAvailable (mrx - GetViewportX (), mry - GetViewportY (), eModeUseinv) == 1) {
            character[GSlocid].RunInteraction(eModeUseinv);
          }
        }
        else {
          if (GoToCharacter(character[GSlocid], 0, NPC_facing_player, 2)) {
            if (IsInteractionAvailable (mrx - GetViewportX (), mry - GetViewportY (), eModeUseinv) == 1) {
              character[GSlocid].RunInteraction(eModeUseinv);        
            }
          }
        }
        SetAction (eMA_Default);
      }     
      else {
        UpdateActionBar();
        ActionLine.TextColor=ActionLabelColorHighlighted;
        #ifnver 3.4
        ProcessClick(x, y, GSagsusedmode);
        #endif
        #ifver 3.4
        Room.ProcessClick(x, y, GSagsusedmode);
        #endif
        SetAction(eMA_Default);
        ItemGiven=null;
      }
    }
    // Mousebutton Right
    else if (button==eMouseRight) {
      if (alternative_action==eMA_Default) {
        SetAction(eMA_Default);
        ActionLine.TextColor=ActionLabelColorHighlighted;
        if (Mouse.Mode==eModeUsermode2) {
          if (ExtensionEx(1, GSlocname)=='e') {
            UpdateActionBar();
            ActionLine.TextColor=ActionLabelColorHighlighted;
            WalkOffScreen();
          }          
          else {
            #ifnver 3.4
            ProcessClick(x, y, eModeWalkto);
            #endif
            #ifver 3.4
            Room.ProcessClick(x, y, eModeWalkto);
            #endif
          }
        }
        else {
          #ifnver 3.4
          ProcessClick(x, y, Mouse.Mode);
          #endif
          #ifver 3.4
          Room.ProcessClick(x, y, Mouse.Mode);
          #endif
        }
      }
      else {
        SetAction(alternative_action);
        used_action=global_action;
        UpdateActionBar();
        ActionLine.TextColor=ActionLabelColorHighlighted;
        GSagsusedmode=Mouse.Mode;
        if (GSagsusedmode==eModeTalkto && IsInteractionAvailable(x, y, GSagsusedmode) && GSloctype==eLocationCharacter) {
          if (approachCharInteract == false) {
            character[GSlocid].RunInteraction(GSagsusedmode);
          }
          else {
            if (GoToCharacter(character[GSlocid], 0, NPC_facing_player,2 )) character[GSlocid].RunInteraction(GSagsusedmode);   
          }
        }
        else {
          
          #ifnver 3.4
          ProcessClick(x, y, GSagsusedmode);
          #endif
          #ifver 3.4
          Room.ProcessClick(x, y, GSagsusedmode);
          #endif          
        }
        SetAction(eMA_Default);
      }
    }
    //left click in inventory
    else if (button==eMouseLeftInv) {
      if (!isAction(eGA_GiveTo))ItemGiven= null;
   
      if (GlobalCondition (eGlob_MouseInvWalk)) {
        // if the mouse is in the inventory and modes Walk is selected
        SetAction (eGA_Use);
        location=GSinvloc;    
        if (Extension()=='u' && ii.IsInteractionAvailable(eModeInteract)) {
          // use it immediately (not with anything else)
          used_action=global_action;
          ii.RunInteraction(eModeInteract);
          SetAction(eMA_Default);
        }
        else {
          if (oldschool_inv_clicks) {
            SetAction (eGA_LookAt);
            used_action=global_action;
            ii.RunInteraction(eModeLookat);   
            SetAction(eMA_Default);
          }
          else player.ActiveInventory=ii;
        }
      } 
      else  if (GlobalCondition(eGlob_InvOnInv)) {
        // if the mode is useinv and the mouse is over the active inv (like "use knife on knife")
        // so do nothing again
      }
      else {
        used_action=global_action;
        if (Mouse.Mode==eModeInteract && ii != null) {
          if (isAction(eGA_Use) && ii.IsInteractionAvailable(eModeInteract)) {
            ActionLine.TextColor=ActionLabelColorHighlighted;
            ii.RunInteraction(eModeInteract);
            SetAction(eMA_Default);
          }
          else player.ActiveInventory=ii;
        }
        else {
          if ( (Mouse.Mode >0 && Mouse.Mode <10 )&& ii != null) {
                GSagsusedmode=Mouse.Mode;
                ActionLine.TextColor=ActionLabelColorHighlighted;
                ii.RunInteraction(Mouse.Mode);
                SetAction(eMA_Default);
          }
        }
      }
    }
    //right click in inventory
    else if (button==eMouseRightInv) {
      if (alternative_action==eMA_Default) {
        SetAction(eMA_Default);
      }
      else {
        SetAction(alternative_action);
        used_action=global_action;
        GSagsusedmode=Mouse.Mode;
        if (Mouse.Mode==eModeInteract && ii != null) {
          if (isAction(eGA_Use) && ii.IsInteractionAvailable(eModeInteract)) {
            UpdateActionBar();
            ActionLine.TextColor=ActionLabelColorHighlighted;
            ii.RunInteraction(eModeInteract);
            SetAction(eMA_Default);
          }
          else player.ActiveInventory=ii;
        }
        else {
          UpdateActionBar();
          ActionLine.TextColor=ActionLabelColorHighlighted;
          inventory[game.inv_activated].RunInteraction(Mouse.Mode);
          SetAction(eMA_Default);
        }
      }
    }
  }
}

function repeatedly_execute_always() {
  // Doubleclick Timer
  if (!IsGamePaused() && !is_gui_disabled()) {
    if (timer_run == true)
    {
      if (disableDoubleclick) {
        timer_run = false;
      }
      else {
        timer_click++;
        if (timer_click >= dc_speed){
          timer_click = 0;
          timer_run = false;
        }
      }
    }
  }
}

function repeatedly_execute() {  
  if (!IsGamePaused() && !is_gui_disabled())
  {
    
    // --- for the MovePlayer function ---
    if (GScancelable==1) {
      GScancelable=0;
      if (InventoryItem.GetAtScreenXY(mouse.x, mouse.y)==null) on_mouse_click(eMouseLeft);
      else on_mouse_click(eMouseLeftInv);
    }
    else if (GScancelable==2) {
      GScancelable=0;
      CheckDefaultAction();
      if (InventoryItem.GetAtScreenXY(mouse.x, mouse.y)==null) on_mouse_click(eMouseRight);
      else on_mouse_click(eMouseRightInv);
    }
    CheckDefaultAction();
    UpdateActionBar();
  }
  // change the arrows in the inventory to show if you
  // can scroll the inventory:
  if (MainInv.TopItem>0) {
    // if inventory can scroll up
    InvUp.NormalGraphic=invUparrowONsprite;
    InvUp.MouseOverGraphic=invUparrowHIsprite;
    
    if (InventoryItem.GetAtScreenXY(gMaingui.X+MainInv.X+1, gMaingui.Y+MainInv.Y+1)==null) MainInv.TopItem-=MainInv.ItemsPerRow;
  }
  else { 
    InvUp.NormalGraphic=invUparrowOFFsprite;
    InvUp.MouseOverGraphic=invUparrowOFFsprite;
  }
  //if inv can scroll down
  if (MainInv.TopItem<MainInv.ItemCount-(MainInv.ItemsPerRow * MainInv.RowCount)) { 
    InvDown.NormalGraphic=invDownarrowONsprite;
    InvDown.MouseOverGraphic=invDownarrowHIsprite;
  }
  else{
    InvDown.NormalGraphic=invDownarrowOFFsprite;
    InvDown.MouseOverGraphic=invDownarrowOFFsprite;
  }
  
}

// ============================= Exports GUI Things===========================================
export ActionLabelColorHighlighted;
export key_l_yes, key_u_yes, key_l_no, key_u_no;
export action_l_keycode;
export action_u_keycode;
export GStopsaveitem;
export listBoxGap;
export ItemGiven;
export lang; a'  // Script header
// 9-verb MI-style template
// Version: 1.5.4
//
// Authors: 
//   Proskrito      first release
//   Lazarus        rewritten for AGS 2.7 
//   SSH            rewritten for AGS 2.71 and AGS 2.72 
//   Rulaman        Maniac Mansion Starterpacks
//   Lucasfan       Maniac Mansion Starterpacks
//   KhrisMUC       AGS 3.0 conversion
//   Electroshokker doubleclick code
//
//   abstauber      current maintainer
//
// 
// Abstract: 
//   This template adds a 9 Verb GUI to AGS,  
//   similar to the ones in classic LucasArts Games.
//   The graphics included may be freely used and altered in any way.
//
//
// Translators:
//   Spanish - Josemarg, Unai, Poplamanopla
//   German  - Abstauber
//   French  - Monsieur OUXX
//   Italian - Paolo
//   Portuguese - Miguel
//
// Contact and Support: 
//   Please visit the AGS-Forums at: http://adventuregamestudio.co.uk/forums
//
//
// Dependencies:
//   AGS 3.1 or later 
//   custom dialog rendering supported in AGS 3.2 or later
//
//
// Revision History
// 0.8    initial re-release
// 0.9    removed the usage of global integers 
//        updated door scripts and code cleanup
//        updated GUI graphics
// 1.0    tweaked the global script(CJ)
// 1.1    added exit extension for hotspots
//        added doubleclicks for exits and doors
// 1.1.1  fixed high-res support
// 1.1.2  added AGS 3.1 support
// 1.2    updated fonts to work in high-res
//        code cleanup, moved options from header to script
// 1.2.1  fixed high-res related inventory bug
//        fixed save GUI glitch
//        simplified inventory variables 
// 1.3    added GUI translations for Spanish, French , Italian and German
//        slightly expanded buttons in options GUI
//        added old school inventory handling
// 1.3.1  altered the way of supporting the old sound system (from AGS 3.1)
//        fixed the quit button label
//        modified the any_click_walk_look_pick function to work with empty strings
// 1.3.2  turned off lip sync by default
// 1.4    added portuguese GUI translation
//        added option to choose if player should approch characters for talking
//        renamed fonts and removed an obsolete one
//        bugfixes
// 1.5    support for AGS 3.4
//        added custom dialog rendering
//        adapted eDirection to enum CharacterDirection (and removed eDir_none)
//        fixed talk-to and pickup interactions on inv items
// 1.5.1  switched to 32-bit and D3D9 by default
//        exit rooms via doubleclick now works on objects
//        option to hide the main gui during dialogs
// 1.5.2  bugfix regarding inventory using keyboard shortcuts
//        added option disable the doubleclick entirely
// 1.5.3  added (optional) talk-to for objects and hotspots

// 1.5.4  fixed label description
//        Selected action is restored after unpausing
//        
//
// Licence:
//
// The MIT License (MIT)
// 
// Copyright (c) 2006-2016 The AGS-Community
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


//----------------------------------------------------------------------------


// If your version of AGS is >=3.2, the new, object oriented audio system will be used.

#ifver 3.2
#define USE_OBJECT_ORIENTED_AUDIO
#endif


#define A_COUNT_ 10  // Action Button Count (gMainGUI)
#define X_SPEED 5    // default Player_Speed
#define MAX_DOORS 99 // How many doors accessed by door script
        
enum eGlobCond {
  eGlob_MouseInvWalk,
  eGlob_MouseInvPickup, 
  eGlob_InvOnInv,
  eGlob_GiveTalkNoChar, 
  eGlob_GiveNoInv, 
  eGlob_InvTalk
};

enum Action {
  eGA_LookAt,
  eGA_TalkTo,
  eGA_GiveTo,
  eGA_PickUp,
  eGA_Use,
  eGA_Open,
  eGA_Close,
  eGA_Push,
  eGA_Pull,
  eGA_UseInv,
  eMA_Default,
  eMA_WalkTo
};

#ifnver 3.4
enum CharacterDirection {
  eDirectionUp,
  eDirectionLeft,
  eDirectionRight,
  eDirectionDown
};
#endif

// for compatibility reasons
enum eDirection {
  eDir_None  = 0, 
  eDir_Up    = eDirectionUp, 
  eDir_Left  = eDirectionLeft, 
  eDir_Right = eDirectionRight, 
  eDir_Down  = eDirectionDown
};

enum eLanguage {
  eLangEN, 
  eLangDE,
  eLangES, 
  eLangIT, 
  eLangFR, 
  eLangPT
};

// ============================= Math & Helper Functions =========================================
import int Absolute(int value);
import int Offset(int point1, int point2);
import int getButtonAction(int action);
import function disable_gui();
import function enable_gui();
import bool is_gui_disabled();
import int GlobalCondition(eGlobCond condition);
import function GetLucasSavegameListBox(ListBox*lb);
import function set_double_click_speed(int speed);
import function InitGuiLanguage();

// ============================= Verb Action Functions ===========================================
import function UsedAction (Action test_action);
import bool isAction(Action test_action);
import function SetActionButtons(Action action, String button_definition);
import function SetDefaultAction(Action def_action);
import function SetAction(Action new_action);
import function SetAlternativeAction(char extension, Action alt_action);
import function CheckDefaultAction();
import function UpdateActionBar();

// ============================= Player/character functions =======================================
import function freeze_player();
import function unfreeze_player();
import function SetPlayer(Character*ch);
#ifnver 3.4
import function FaceDirection (this Character*, CharacterDirection dir);
#endif
import function EnterRoom(this Character*, int newRoom, int x, int y, CharacterDirection dir);
import function Go();
import function set_approaching_char(bool enable);
// ================ Cancelable, semi-blocking move-player-character functions =====================
import int MovePlayer(int x, int y);
import int GoToCharacter(Character*charid, CharacterDirection dir, bool NPCfacesplayer, int blocking);
import int NPCGoToCharacter(Character*charidwhogoes, Character*charidtogoto, CharacterDirection dir, bool NPCfacesplayer, int blocking);
import int MovePlayerEx(int x, int y, WalkWhere direct);
import int GoToCharacterEx(Character*chwhogoes, Character*ch, CharacterDirection dir, int xoffset, int yoffset, bool NPCfacesplayer, int blocking);
import int any_click_move(int x, int y, CharacterDirection dir);
import int any_click_walk(int x, int y, CharacterDirection dir);
import int any_click_walk_look(int x, int y, CharacterDirection dir, String lookat);

#ifdef USE_OBJECT_ORIENTED_AUDIO
  import int any_click_walk_look_pick(int x, int y, CharacterDirection dir, String lookat, int objectID, InventoryItem*item, AudioClip *sound=false);
#endif

#ifndef USE_OBJECT_ORIENTED_AUDIO
  import int any_click_walk_look_pick(int x, int y, CharacterDirection dir, String lookat, int objectID, InventoryItem*item, int sound=0);
#endif

import int any_click_use_inv (InventoryItem*item, int x, int y, CharacterDirection dir);
import function GoTo(int blocking);
// ============================= Unhandled Events =================================================
import function Unhandled(int door_script=0);

// ============================= Door functions ==========================================
import function set_door_state(int door_id, int value);
import int get_door_state(int door_id);
import function init_object(int door_id, int act_object);
import function set_door_strings(String lookat =false, String islocked =false, String wrongitem =false, String closefirst =false, String unlock =false, String relock =false);
import String get_door_strings(String what_type);
import int any_click_on_door(int door_id, int act_object, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir);
#ifdef USE_OBJECT_ORIENTED_AUDIO
    import int any_click_on_door_special (int door_id, int act_object, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir, AudioClip *opensound, AudioClip *closesound, int key, int closevalue);
#endif

#ifndef USE_OBJECT_ORIENTED_AUDIO
    import int any_click_on_door_special (int door_id, int act_object, int x, int y, CharacterDirection dir, int nr_room, int nr_x, int nr_y, CharacterDirection nr_dir, int opensound=0, int closesound=0, int key, int closevalue);
#endif
// ============================= translation ====================================================
import String clearToSpace(String text);
import int getInteger();
import function TranslateAction(int action, int tr_lang=eLangEN);
import function AdjustLanguage();
import function AdjustGUIText();

// ============================= Extensions functions ==========================================
import function RemoveExtension();
import function AddExtension(char extension);
import char Extension();
import function OpenCloseExtension(int door_id);
import function VariableExtensions(); �]        ej��