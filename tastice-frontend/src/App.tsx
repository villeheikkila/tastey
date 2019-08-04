import { useQuery } from '@apollo/react-hooks';
import { createMuiTheme, CssBaseline } from '@material-ui/core';
import { blue, pink } from '@material-ui/core/colors';
import { ThemeProvider } from '@material-ui/styles';
import React, { createContext, useEffect, useState } from 'react';
import { Routes } from './components/Routes';
import { THEME } from './graphql';

const darkTheme = createMuiTheme({
    palette: {
        type: 'dark',
        primary: blue,
        secondary: pink,
    },
});

const whiteTheme = createMuiTheme({
    palette: {
        primary: blue,
        secondary: pink,
    },
});

interface UserContext {
    token: string;
    setToken: React.Dispatch<string | null>;
    id: string;
}

export const App = (): JSX.Element => {
    const [token, setToken] = useState();
    const [id, setId] = useState();
    const themeSwitcher = useQuery(THEME);
    const theme = themeSwitcher.data.theme ? 1 : 0;
    const themes = [darkTheme, whiteTheme];

    useEffect((): void => {
        const token = localStorage.getItem('token');
        const userId = localStorage.getItem('id');
        if (token) {
            setToken(token);
            setId(userId);
        }
    }, [token]);

    return (
        <div>
            <ThemeProvider theme={themes[theme]}>
                <CssBaseline />
                <UserContext.Provider value={{ setToken, token, id }}>
                    <Routes />
                </UserContext.Provider>
            </ThemeProvider>
        </div>
    );
};

export const UserContext = createContext<UserContext>({
    id: '',
    token: '',
    setToken: () => {},
});
