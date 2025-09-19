using Godot;
using System;
using System.Threading;
using System.IO.Ports;

public partial class SerialController : Node
{
	public static SerialController Instance { get; private set; }
	
	private SerialPort serialPort;
	[Signal] 
	public delegate void SerialDataReceivedEventHandler(string data);
	[Signal]
	public delegate void SerialErrorEventHandler(string error);
	private string serialDataReceived;
	private string[] currentPorts;
	private int currentPortIndex;
	private int baudRate = 115200;

	public string portName { get; set; }

	public override void _Ready()
	{
		Instance = this;
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
					//GD.Print(serialDataReceived);
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
	
	public static string[] _GetAllPorts()
	{
		return SerialPort.GetPortNames();
		//Only works on Mac
	}

	public void _OpenPort()
	{
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

	public void _ClosePort()
	{
		serialPort.Close();
	}

	public void _setConnectedPort(string portName)
	{
		this.portName = portName;
		serialPort = new SerialPort(portName, baudRate);
		serialPort.ReadTimeout = 10;
		GD.Print($"Now connected to port: {portName}.");
	}

	public String _GetPort()
	{
		return portName;
	}
}

