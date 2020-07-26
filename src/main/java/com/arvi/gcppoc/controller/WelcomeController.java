package com.arvi.gcppoc.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
public class WelcomeController {

	private static final Logger logger = LoggerFactory.getLogger(WelcomeController.class.getName());
	
	@GetMapping(path = {"/welcome", "/"})
	public ModelAndView welcome(@AuthenticationPrincipal OidcUser user) {
		ModelAndView mav = new ModelAndView();
		logger.info("User : {}", user.getUserInfo().getPreferredUsername());
		mav.addObject("user", user.getUserInfo());
		mav.addObject("idToken", user.getIdToken().getTokenValue());
		mav.setViewName("welcome");
		return mav;
	}

}
