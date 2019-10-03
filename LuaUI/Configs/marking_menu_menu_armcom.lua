local menu_armcom = {
  items = {
  {
    angle = 0,
    unit = "staticmex",
    label = "Economy",
    items = {
      {
        angle = 45,
        unit = "energysingu"
      },
      {
        angle= 90,
        unit = "energyfusion",
      },
      {
        angle= 135,
        unit = "energygeo",
      },
      --{
      --  angle = -45,
      --  unit = "cortide",
      --},
      {
        angle = -45,
        unit = "staticcon",
      },
      {
        angle= -90,
        unit = "energysolar",
      },
      {
        angle= -135,
        unit = "energywind",
      },
    }
  },
  {
    angle = -45,
    unit = "factoryplane",
    label = "Air/Sea Facs",
    items = {
      {
        angle = 90,
        unit = "factorygunship"
      },
      {
        angle = -135,
        unit = "factoryamph"
      },
      {
        angle = 180,
        unit = "factoryship"
      },
      {
        angle = 0,
        unit = "staticrearm"
      },
    }
  },
  {
    angle = -90,
    unit = "factorycloak",
    label = "Land Facs",
    items = {
	  {
        angle = 0,
        unit = "factoryshield"
      },
	  {
        angle = 45,
        unit = "factoryjump"
      },
	  {
        angle = -45,
        unit = "factoryspider"
      },
      {
        angle = 180,
        unit = "factoryveh"
      },
      {
        angle = 135,
        unit = "factorytank"
      },
	  {
        angle = -135,
        unit = "factoryhover"
      },
    }
  },
  {
    angle = 180,
    unit = "turretlaser",
    label = "Defense",
    items = {
      {
        angle = 45,
        unit = "turretmissile"
      },
      {
        angle = 90,
        unit = "turretheavylaser"
      },
      {
        angle = 135,
        unit = "turretimpulse"
      },
      {
        angle = -90,
        unit = "turretriot"
      },
      {
        angle = -135,
        unit = "turretemp"
      },
      {
        angle = -45,
        unit = "turretgauss"
      }
    }
  },
  {
    angle = 135,
    unit = "turretmissile",
    label = "AA/AS",
    items = {
      {
        angle = 0,
        unit = "turretaaheavy"
      },
      {
        angle = -90,
        unit = "turretaalaser"
      },
      {
        angle = 45,
        unit = "turretaaflak"
      },
      {
        angle = -135,
        unit = "turretaaclose"
      },
      {
        angle = 90,
        unit = "turretaafar"
      },
      {
        angle = 180,
        unit = "turrettorp"
      }
    }
  },
  {
    angle = 90,
    unit = "staticradar",
    label = "Support",
    items = {
      {
        angle = 0,
        unit = "staticheavyradar"
      },
      {
        angle = -180,
        unit = "staticshield"
      },
      {
        angle = 135,
        unit = "staticjammer"
      },
	  {
        angle = -45,
        unit = "energypylon"
      },
      {
        angle = -135,
        unit = "staticstorage"
      },
	}
  },
  {
    angle = -135,
    unit = "staticantinuke",
    label = "Super",
    items = {
      {
        angle = 0,
        unit = "staticnuke"
      },
      {
        angle = 90,
        unit = "staticmissilesilo"
      },
	  {
        angle = 135,
        unit = "turretantiheavy"
      },
      {
        angle = 180,
        unit = "turretheavy"
      },
      {
        angle = -45,
        unit = "staticarty"
      },
      {
        angle = -90,
        unit = "staticheavyarty"
      }
    }
  },
  {
    angle = 45,
    unit = "mahlazer",
    label = "Costly",
    items = {
       {
        angle = 315,
        unit = "striderhub"
       },
	   {
        angle = 180,
        unit = "raveparty"
       },
	   {
        angle = 0,
        unit = "zenith"
       },
    },
  },
  },
}

return menu_armcom
