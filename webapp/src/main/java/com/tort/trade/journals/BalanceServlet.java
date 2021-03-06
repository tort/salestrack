package com.tort.trade.journals;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class BalanceServlet  extends HttpServlet {

	@SuppressWarnings({"unchecked"})
    @Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		TransitionConversation conversation = (TransitionConversation) req.getSession().getAttribute("conversation");
		Action action = new BalanceAction(conversation.getHibernateSession(), new JournalQueryFactoryImpl(), req.getParameterMap());
		
		action.act().render(resp);
	}
}
