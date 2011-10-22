local menu_armcsa = {
	items = {
	  {
		angle = 0,
		unit = "cormex",
		label = "Economy",
		items = {
		  {
			angle= -90,
			unit = "armsolar",
		  },
		  {
			angle= -135,
			unit = "armwin",
		  },
        {
			angle = -45,
			unit = "armnanotc"
		  },
		}
	  },
	  {
		angle = -90,
		unit = "armrectr",
		label = "Bots",
		items = {
		  {
			angle= -45,
			unit = "armflea",
		  },
		  { 
			angle = -135,
			unit = "corak",
		  },
		  { 
			angle = -180,
			unit = "spherepole",
		  },
		  { 
			angle = 0,
			unit = "corcrash",
		  },

		}
	  },
	{
		angle = -45,
		unit = "armsptk",
		label = "Walkers",
		items = {
		  { 
			angle = -90,
			unit = "armsnipe",
		  },
		  {
			angle = 0,
			unit = "armspy"
		  },
		  {
			angle = 90,
			unit = "slowmort"
		  },
		}
	  },
	  {
		angle = 180,
		unit = "corllt",
		label = "Defense",
		items = {
		  {
			angle = 45,
			unit = "corrl"
		  },
		  {
			angle = 135,
			unit = "armartic"
		  },
		  {
			angle = -45,
			unit = "corhlt"
		  },
		  {
			angle = -135,
			unit = "armdeva"
		  },
		  {
			angle = 90,
			unit = "corgrav"
		  },
		  {
			angle = -90,
			unit = "cortl"
		  },	  	  
		}
	  },
	  {
		angle = 90,
		unit = "corrad",
		label = "Auxillary",
		items = {
		  {
			angle = -135,
			unit = "armjamt"
		  },
		  {
			angle = 45,
			unit = "armsonar"
		  },
		}
	  },
  {
    angle = -135,
    unit = "armcomdgun",
    label = "Sriders",
    items = {
      {
        angle = 0,
        unit = "dante"
      },
      --[[{
        angle = 90,
        unit = "armshock"
      },]]
      {
        angle = -90,
        unit = "armbanth"
      },
      {
        angle = 180,
        unit = "armorco"
      },
      {
        angle = 90,
        unit = "gorg"
      },
      {
        angle = 135,
        unit = "armraven"
      },
      {
        angle = -45,
        unit = "scorpion"
      },	  
    }
  },
	}
}

return menu_armcsa

