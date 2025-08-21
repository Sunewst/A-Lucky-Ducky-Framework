using Godot;
using System;
using System.Threading;
using System.IO.Ports;

public partial class SerialController : Node
{
	private SerialPort serialPort;
	[Signal] 
	public delegate void SerialDataReceivedEventHandler(string data);
	[Signal]
	public delegate void SerialErrorEventHandler(string error);
	private string serialDataReceived;
	private string[] currentPorts;
	private int currentPortIndex;

	public override void _Ready()
	{
		currentPorts = SerialPort.GetPortNames();
		for (var i = 0; i < SerialPort.GetPortNames().Length; i++)
		{
			//GD.Print(i +": " + _currentPorts[i]);
		}
		GD.Print("Which port would you like to open?");

		string portName = "/dev/cu.usbmodem11301";
		var baudRate = 115200;
		

		serialPort = new SerialPort(portName, baudRate);
		serialPort.ReadTimeout = 10;
		try
		{
			serialPort.Open();
			serialPort.DtrEnable = true;
			Thread.Sleep(150);
			GD.Print($"Successfully opened port {portName}.");
		}
		catch (Exception ex)
		{
			GD.PrintErr($"Could not open serial port: {ex.Message}");
			EmitSignal(SignalName.SerialError, ex.Message);
		}
	}

	public override void _Process(double delta)
	{
		if (serialPort != null && serialPort.IsOpen)
		{
			try
			{
				if (serialPort.BytesToRead > 0)
				{
					serialDataReceived = serialPort.ReadLine();
					GD.Print(serialDataReceived);
					EmitSignal(SignalName.SerialDataReceived, serialDataReceived);
				}
			}
			catch (TimeoutException)
			{
			}
		}
	}

	public override void _ExitTree()
	{
		if (serialPort != null && serialPort.IsOpen)
		{
			serialPort.Close();
		}
	}
	
	private static string[] _GetAllPorts()
	{
		return SerialPort.GetPortNames();
	}
}

