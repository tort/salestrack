package com.tort.trade.model;

import java.util.Arrays;
import java.util.List;

import org.testng.annotations.Test;

@Test
public class SalesEntityTest extends EntityTest{
	public void newSales(){
		_session.save(new Sales("sales name"));
		_session.flush();
	}

	@Override
	protected List<Class> getClasses() {
		return Arrays.asList(new Class[]{
				Sales.class
		});
	}
}
