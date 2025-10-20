import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { SafeAreaView, StyleSheet, View } from 'react-native';
import Game from './src/Game';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
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
