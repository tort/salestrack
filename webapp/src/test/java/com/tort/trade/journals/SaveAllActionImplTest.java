package com.tort.trade.journals;

import static org.easymock.EasyMock.createMock;
import static org.easymock.EasyMock.expect;
import static org.easymock.EasyMock.isA;
import static org.easymock.EasyMock.replay;
import static org.testng.AssertJUnit.assertEquals;
import static org.testng.AssertJUnit.fail;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hibernate.Session;
import org.testng.annotations.Test;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.tort.trade.model.Transition;

@Test
public class SaveAllActionImplTest extends ActionTest {
	
	public void newActionNegative(){
		try{
			new SaveAllAction(new HashMap<String, String[]>(), null, null);
			fail();
		} catch (IllegalArgumentException e) {

		}
	}
	
	public void newActionPositive(){
		Map<String, String[]> params = new HashMap<String, String[]>();
		params.put("data", new String[]{"[{_goodId: 1, _text: \"драссте вам\", _lid: 1}]"});		
		
		new  SaveAllAction(params, null, null);
	}
	
	public void actImpl(){
		Action action = positiveSetUp();
		
		List<TransitionErrorTO> transitionTOs = new ArrayList<TransitionErrorTO>();
		transitionTOs.add(new TransitionErrorTO(5L, new ConvertTransitionException().getMessage()));
		transitionTOs.add(new TransitionErrorTO(2L, new ConvertTransitionException().getMessage()));
		
		byte[] result = action.act();		
		
		assertEquals(new Gson().toJson(transitionTOs).getBytes(), result);
	}
	
	protected Action positiveSetUp() {
		Session session = createMock(Session.class);
		TransitionConverter converter = createMock(TransitionConverter.class);
		
		Map<String, String[]> params = new HashMap<String, String[]>();
		params.put("data", new String[]{"[{_goodId: 5, _text: \"bad_data\", _lid: 5}, {_goodId: 1, _text: \"good_data\", _lid: 1}, {_goodId: 2, _text: \"bad_data\", _lid: 2}]"});		
		
		SaveAllAction action = new  SaveAllAction(params, session, converter);
		
		expect(session.save(isA(Transition.class))).andStubReturn(1L);
		try {
			expect(converter.convertToEntity(isA(TransitionTO.class))).andThrow(new ConvertTransitionException());
			expect(converter.convertToEntity(isA(TransitionTO.class))).andReturn(new ArrayList<Transition>());
			expect(converter.convertToEntity(isA(TransitionTO.class))).andThrow(new ConvertTransitionException());
		} catch (ConvertTransitionException e) {
			e.printStackTrace();
		}
		replay(converter, session);
		
		return action;
	}
}
