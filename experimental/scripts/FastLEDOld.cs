using Godot;
using System;

[GlobalClass]
public partial class FastLEDOld : Node
{
    private static Godot.Collections.Array leds_array = [];

    public static void show()
    {
        
    }
    
    public static void addLeds(Godot.Color[] targetArray)
    {
        leds_array.Add(targetArray);
        GD.Print(leds_array);
    }
    
    public static void printLedsArray()
    {
        GD.Print(leds_array);
    }
}
