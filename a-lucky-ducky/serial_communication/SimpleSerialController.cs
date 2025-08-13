using Godot;
using System;
using System.Threading;
using System.IO.Ports;

public partial class SimpleSerialController : Node
{
	private SerialPort _serialPort;
	[Signal] 
	public delegate void SerialDataReceivedEventHandler(string data);
	[Signal]
	public delegate void SerialErrorEventHandler(string error);
	private string _serialDataReceived;
	private string[] _currentPorts;
	private int _currentPortIndex;

	public override void _Ready()
	{
		_currentPorts = SerialPort.GetPortNames();
		for (int i = 0; i < SerialPort.GetPortNames().Length; i++)
		{
			//GD.Print(i +": " + _currentPorts[i]);
		}
		GD.Print("Which port would you like to open?");

		string portName = "/dev/cu.usbmodem11301";
		int baudRate = 115200;
		

		_serialPort = new SerialPort(portName, baudRate);
		_serialPort.ReadTimeout = 10;
		try
		{
			_serialPort.Open();
			_serialPort.DtrEnable = true;
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
		if (_serialPort != null && _serialPort.IsOpen)
		{
			try
			{
				if (_serialPort.BytesToRead > 0)
				{
					_serialDataReceived = _serialPort.ReadLine();
					GD.Print(_serialDataReceived);
					EmitSignal(SignalName.SerialDataReceived, _serialDataReceived);
				}
			}
			catch (TimeoutException)
			{
			}
		}
	}

	public override void _ExitTree()
	{
		if (_serialPort != null && _serialPort.IsOpen)
		{
			_serialPort.Close();
		}
	}
	
	public static string[] _GetAllPorts()
	{
		return SerialPort.GetPortNames();
	}

	
	
	
	
}

