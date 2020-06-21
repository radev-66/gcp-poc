package com.arvi.gcppoc.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

@Controller
public class LogoutController {

    @GetMapping("/app-logout")
    public ModelAndView  logout(HttpServletRequest request, @AuthenticationPrincipal OidcUser user) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        ModelAndView mav = new ModelAndView();
        mav.setViewName("redirect:https://dev-774785.okta.com/oauth2/default/v1/logout?id_token_hint=" + user.getIdToken().getTokenValue());
        return mav;
    }

}
