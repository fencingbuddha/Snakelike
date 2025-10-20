import React from 'react';
import { SafeAreaView, StatusBar, StyleSheet, View } from 'react-native';
import Game from './src/Game';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" />
      <View style={styles.gameWrapper}>
        <Game />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#060913'
  },
  gameWrapper: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 24
  }
});
