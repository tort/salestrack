package com.tort.trade.journals;

public class ConvertTransitionException extends Exception {
	public ConvertTransitionException(){
		super("Строка передач составлена неверно");
	}

	public ConvertTransitionException(String text) {
		super(text);
	}
}
