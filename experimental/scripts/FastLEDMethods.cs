using Godot;
using System;

public partial class FastLEDMethods : Node
{
	public void fill_solid(Godot.Color[] targetArray, int numToFill, Godot.Color color)
	{
		for (var i = 0; i < numToFill; i++)
		{
			targetArray[i] = color;
		}
	}
}
