using Godot;
using System;
using System.IO.Ports;

public partial class SimpleSerialController : Node
{
	private SerialPort _serialPort;

	public override void _Ready()
	{

		string portName = "COM3"; 
		int baudRate = 9600;

		_serialPort = new SerialPort(portName, baudRate);
		_serialPort.ReadTimeout = 10; 
		try
		{
			_serialPort.Open();
			GD.Print($"✅ Successfully opened port {portName}.");
		}
		catch (Exception ex)
		{
			GD.PrintErr($"❌ Could not open serial port: {ex.Message}");
		}
	}

	public override void _Process(double delta)
	{
		if (_serialPort != null && _serialPort.IsOpen)
		{
			try
			{
				string message = _serialPort.ReadLine();
				GD.Print($"Received: {message.Trim()}");
			}
			catch (TimeoutException)
			{
			}
		}
		else
		{
			GD.Print("Waiting for connection... No device connected or port is not open.");
		}
	}

	public override void _ExitTree()
	{
		if (_serialPort != null && _serialPort.IsOpen)
		{
			_serialPort.Close();
		}
	}
}
