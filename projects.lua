
local hypertext_basic = [[
	<bigger>Normal test</bigger>\nThis is a normal text.
	]]

-- NOTE: Use backslash (\) to masking your escape sequence to render properly in editor. This is relevant in some cases.
sfse.projects = {

    ht = {
        {"container", {0, 0}},
        {"hypertext", {0, 0}, {1,5}, "hypertext", hypertext_basic},
        {"container_end"},
    },

    noclip = {
        {"style_type", "textarea", "noclip=true"},
        {"style_type", "list", "noclip=true"},
        {"textarea", {1, 1}; {3, 3}; "list"; "list"; ""},
        {"list", "current_player", "main", {13.12, 0.75}, {2, 2}},
    },

	esc = {
        {"label", {1, 1}, "Test\\nnextline"},
        {"label", {1, 2}, "Test\\tTab"}
    },

    str = [[
        formspec_version[6]
        size[20,7.5]
        style_type[textarea;noclip=true]
        style_type[list;noclip=true]
        textarea[1,1;2,0.5;list;listtest;]
        button[3,1;3,0.5;help;yes\nyes]
        button[6,1;3,0.5;help;yes\nyes]
        button[9,1;3,0.5;help;yes]
    ]],

    test = [[
		size[12,13]
		image_button[0,0;1,1;logo.png;rc_image_button_1x1;1x1]
		image_button[1,0;2,2;logo.png;rc_image_button_2x2;2x2]
		button[0,2;1,1;rc_button_1x1;1x1]
		button[1,2;2,2;rc_button_2x2;2x2]
		item_image[0,4;1,1;air]
		item_image[1,4;2,2;air]
		item_image_button[0,6;1,1;testformspec:node;rc_item_image_button_1x1;1x1]
		item_image_button[1,6;2,2;testformspec:node;rc_item_image_button_2x2;2x2]
		field[3,.5;3,.5;rc_field;Field;text]
		pwdfield[6,.5;3,1;rc_pwdfield;Password Field]
		field[3,1;3,1;;Read-Only Field;text]
		textarea[3,2;3,.5;rc_textarea_small;Textarea;text]
		textarea[6,2;3,2;rc_textarea_big;Textarea;text\nmore text]
		textarea[3,3;3,1;;Read-Only Textarea;text\nmore text]
		textlist[3,4;3,2;rc_textlist;Textlist,Perfect Coordinates;1;false]
		tableoptions[highlight=#ABCDEF75;background=#00000055;border=false]
		table[6,4;3,2;rc_table;Table,Cool Stuff,Foo,Bar;2]
		dropdown[3,6;3,1;rc_dropdown_small;This,is,a,dropdown;1]
		dropdown[6,6;3,2;rc_dropdown_big;I,am,a,bigger,dropdown;5]
		image[0,8;3,2;ignore.png]
		box[3,7;3,1;#00A3FF]
		checkbox[3,8;rc_checkbox_1;Check me!;false]
		checkbox[3,9;rc_checkbox_2;Uncheck me now!;true]
		scrollbar[0,11.5;11.5,.5;horizontal;rc_scrollbar_horizontal;500]
		scrollbar[11.5,0;.5,11.5;vertical;rc_scrollbar_vertical;0]
		list[current_player;main;6,8;3,2;1]
		button[9,0;2.5,1;rc_empty_button_1;]
		button[9,1;2.5,1;rc_empty_button_2;]
		button[9,2;2.5,1;rc_empty_button_3;] ]]..
		"label[9,0.5;This is a label.\\nLine\\nLine\\nLine\\nEnd]"..
		[[button[9,3;1,1;rc_empty_button_4;]
		vertlabel[9,4;VERT]
		label[10,3;HORIZ]
		tabheader[8,0;6,0.65;rc_tabheader;Tab 1,Tab 2,Tab 3,Secrets;1;false;false]
	]],
	model = [[
		formspec_version[3]
		size[12,13]
		style[m1;bgcolor=black]
		style[m2;bgcolor=black]
		label[5,1;all defaults]
		label[5,5.1;angle = 0, 180
continuous = false
mouse control = false
frame loop range = 0,30]
		label[5,9.2;continuous = true
mouse control = true]
		model[0.5,0.1;4,4;m1;character.b3d;character.png]
		model[0.5,4.2;4,4;m2;character.b3d;character.png;0,180;false;false;0,30]
	]]
}