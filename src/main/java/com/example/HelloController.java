package com.example;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    // obtencion de propiedades

    @Value("${greeter.message}")
    private String greeterMessage;

    @Value("${greeter.varmessage}")
    private String greeterVarMessage;


    @RequestMapping("/")
    String hello() {
        String messageFormat="Mensajes:\n - message:%s \n - varmessage: %s\n";
        return String.format(messageFormat, greeterMessage, greeterVarMessage);
    }

}
